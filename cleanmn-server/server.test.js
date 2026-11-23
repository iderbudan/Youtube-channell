import assert from 'node:assert/strict';
import http from 'node:http';
import { test } from 'node:test';

import { FakeQPayClient } from './qpay.js';
import { createApp } from './server.js';
import { OrderStore } from './store.js';

const catalog = [
  { id: 'p01', name: 'Саван', unit: '500мл', price: 6500, category: 'soap', inStock: true },
  { id: 'p07', name: 'Моп', unit: 'ш', price: 45000, category: 'broom', inStock: true },
];

async function withServer(fn) {
  const app = createApp({
    catalog, store: new OrderStore(null), qpay: new FakeQPayClient(),
    config: { publicUrl: 'http://t', adminToken: 'adm', callbackSecret: 'sec', deliveryFee: 5000, freeDeliveryThreshold: 50000 },
  });
  const srv = http.createServer(app).listen(0);
  const base = `http://127.0.0.1:${srv.address().port}`;
  const call = async (method, path, body, headers = {}) => {
    const r = await fetch(base + path, {
      method, headers: { 'Content-Type': 'application/json', ...headers },
      body: body ? JSON.stringify(body) : undefined,
    });
    const t = await r.text();
    let j; try { j = JSON.parse(t); } catch { j = t; }
    return { status: r.status, body: j };
  };
  try { await fn(call); } finally { srv.close(); }
}

const delivery = { name: 'Бат', phone: '99112233', district: 'Баянгол', khoroo: '3', address: '12-р байр' };

test('захиалга → QPay → төлбөр → админ төлөв', () => withServer(async (call) => {
  const p = await call('GET', '/api/products');
  assert.equal(p.body.length, 2);

  // Клиентээс ирсэн үнийг тоохгүй, сервер өөрөө тооцно
  const o = await call('POST', '/api/orders', { items: [{ productId: 'p01', quantity: 2, price: 1 }], delivery });
  assert.equal(o.status, 201);
  assert.equal(o.body.subtotal, 13000);
  assert.equal(o.body.deliveryFee, 5000);
  const { id, token } = o.body;

  assert.equal((await call('GET', `/api/orders/${id}?token=bad`)).status, 403);

  const inv = await call('POST', `/api/orders/${id}/qpay?token=${token}`);
  assert.equal(inv.body.amount, 18000);
  assert.ok(inv.body.qrText);

  let chk = await call('POST', `/api/orders/${id}/payment-check?token=${token}`);
  assert.equal(chk.body.paid, false);
  // QPay callback (нууцгүй бол татгалзана)
  assert.equal((await call('GET', `/api/qpay/callback?order=${id}`)).status, 403);
  await call('GET', `/api/qpay/callback?order=${id}&s=sec`);
  chk = await call('POST', `/api/orders/${id}/payment-check?token=${token}`);
  assert.equal(chk.body.paid, true);
  assert.equal(chk.body.order.status, 'paid');

  assert.equal((await call('PATCH', `/api/admin/orders/${id}`, { status: 'delivering' })).status, 401);
  const upd = await call('PATCH', `/api/admin/orders/${id}`, { status: 'delivering' }, { Authorization: 'Bearer adm' });
  assert.equal(upd.body.status, 'delivering');
  const prods = await call('GET', '/api/products');
  assert.equal(prods.body.find((x) => x.id === 'p01').orderCount, 2); // төлөгдсөн 2ш тоологдоно
  const got = await call('GET', `/api/orders/${id}?token=${token}`);
  assert.deepEqual(got.body.history.map((h) => h.status), ['pending_payment', 'paid', 'delivering']);
}));

test('50,000₮-с дээш үнэгүй хүргэлт, буруу утас', () => withServer(async (call) => {
  const o = await call('POST', '/api/orders', { items: [{ productId: 'p07', quantity: 2 }], delivery });
  assert.equal(o.body.deliveryFee, 0);
  const bad = await call('POST', '/api/orders', { items: [{ productId: 'p07', quantity: 1 }], delivery: { ...delivery, phone: '123' } });
  assert.equal(bad.status, 400);
}));
