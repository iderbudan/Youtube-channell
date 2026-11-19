// CleanMN backend: бүтээгдэхүүн, захиалга, QPay нэхэмжлэх/шалгалт, захиалгын төлөв.
// Гадны сангүй (Node 18+). Ажиллуулах: `node server.js`
import crypto from 'node:crypto';
import fs from 'node:fs';
import http from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { FakeQPayClient, QPayClient } from './qpay.js';
import { OrderStore } from './store.js';

const dir = path.dirname(fileURLToPath(import.meta.url));
loadDotEnv(path.join(dir, '.env'));

const cfg = {
  port: Number(process.env.PORT || 8080),
  publicUrl: (process.env.PUBLIC_URL || `http://localhost:${process.env.PORT || 8080}`).replace(/\/$/, ''),
  adminToken: process.env.ADMIN_TOKEN || '',
  callbackSecret: process.env.CALLBACK_SECRET || '',
  deliveryFee: 5000,
  freeDeliveryThreshold: 50000,
};

export const STATUSES = ['pending_payment', 'paid', 'preparing', 'delivering', 'delivered', 'cancelled'];
const PHONE_RE = /^[6-9]\d{7}$/;

export function createApp({ catalog, store, qpay, config = cfg }) {
  const byId = new Map(catalog.map((p) => [p.id, p]));

  const publicOrder = (o) => {
    const { invoice, ...rest } = o; // нэхэмжлэхийн дотоод мэдээллийг жагсаалтад өгөхгүй
    return rest;
  };

  const authOrder = (req, id) => {
    const o = store.get(id);
    if (!o) throw httpError(404, 'Захиалга олдсонгүй');
    const token = req.query.get('token') || '';
    if (!safeEqual(token, o.token)) throw httpError(403, 'Хандах эрхгүй');
    return o;
  };

  const setStatus = (o, status) => {
    if (o.status === status) return o;
    o.status = status;
    o.history.push({ status, at: new Date().toISOString() });
    return store.save(o);
  };

  /** QPay-ээс шалгаад, бүтэн дүн орсон бол "paid" болгоно. */
  const syncPayment = async (o) => {
    if (o.status !== 'pending_payment' || !o.invoice) return o;
    const paid = await qpay.paidAmount(o.invoice.invoiceId);
    if (paid >= o.subtotal + o.deliveryFee) {
      o.paidAmount = paid;
      return setStatus(o, 'paid');
    }
    return o;
  };

  const routes = [
    ['GET', /^\/api\/health$/, () => ({ ok: true })],

    ['GET', /^\/api\/products$/, () => catalog],

    ['POST', /^\/api\/orders$/, async (req) => {
      const body = await readJson(req);
      const items = Array.isArray(body.items) ? body.items : [];
      if (items.length === 0 || items.length > 50) throw httpError(400, 'Сагс хоосон байна');
      const lines = items.map((i) => {
        const p = byId.get(String(i.productId));
        const q = Number(i.quantity);
        if (!p || !p.inStock) throw httpError(400, 'Бүтээгдэхүүн олдсонгүй эсвэл дууссан');
        if (!Number.isInteger(q) || q < 1 || q > 99) throw httpError(400, 'Тоо ширхэг буруу');
        return { productId: p.id, name: `${p.name} (${p.unit})`, price: p.price, quantity: q };
      });
      const d = body.delivery || {};
      const delivery = {
        name: str(d.name, 80), phone: str(d.phone, 8), district: str(d.district, 40),
        khoroo: str(d.khoroo, 3), address: str(d.address, 300), note: str(d.note, 300),
      };
      if (!delivery.name || !delivery.district || !delivery.khoroo || !delivery.address) {
        throw httpError(400, 'Хүргэлтийн мэдээлэл дутуу байна');
      }
      if (!PHONE_RE.test(delivery.phone)) throw httpError(400, 'Утасны дугаар буруу');

      const subtotal = lines.reduce((s, l) => s + l.price * l.quantity, 0);
      const now = new Date().toISOString();
      const order = {
        id: crypto.randomUUID(),
        number: store.nextNumber(),
        token: crypto.randomBytes(24).toString('base64url'),
        lines,
        delivery,
        subtotal,
        deliveryFee: subtotal >= config.freeDeliveryThreshold ? 0 : config.deliveryFee,
        status: 'pending_payment',
        createdAt: now,
        history: [{ status: 'pending_payment', at: now }],
      };
      store.save(order);
      return [201, publicOrder(order)];
    }],

    ['GET', /^\/api\/orders\/([\w-]+)$/, async (req, [id]) => publicOrder(authOrder(req, id))],

    ['POST', /^\/api\/orders\/([\w-]+)\/qpay$/, async (req, [id]) => {
      const o = authOrder(req, id);
      if (o.status !== 'pending_payment') throw httpError(409, 'Энэ захиалга төлөгдсөн байна');
      if (!o.invoice) {
        const cb = new URL(`${config.publicUrl}/api/qpay/callback`);
        cb.searchParams.set('order', o.id);
        if (config.callbackSecret) cb.searchParams.set('s', config.callbackSecret);
        o.invoice = await qpay.createInvoice({
          senderInvoiceNo: o.number,
          receiverCode: o.delivery.phone,
          description: `CleanMN захиалга ${o.number}`,
          amount: o.subtotal + o.deliveryFee,
          callbackUrl: cb.toString(),
        });
        store.save(o);
      }
      return o.invoice;
    }],

    ['POST', /^\/api\/orders\/([\w-]+)\/payment-check$/, async (req, [id]) => {
      const o = await syncPayment(authOrder(req, id));
      return { paid: o.status !== 'pending_payment' && o.status !== 'cancelled', order: publicOrder(o) };
    }],

    // QPay төлбөр орсны дараа энэ URL-ыг дуудна. Payload-д итгэлгүй — QPay API-аас дахин шалгана.
    ['ANY', /^\/api\/qpay\/callback$/, async (req) => {
      if (config.callbackSecret && !safeEqual(req.query.get('s') || '', config.callbackSecret)) {
        throw httpError(403, 'forbidden');
      }
      const o = store.get(req.query.get('order') || '');
      if (o) await syncPayment(o);
      return [200, 'SUCCESS'];
    }],

    // ---- Админ (хүргэлтийн ажилтан / оператор) ----
    ['GET', /^\/api\/admin\/orders$/, (req) => {
      requireAdmin(req);
      const status = req.query.get('status');
      return store.all().filter((o) => !status || o.status === status).map(publicOrder);
    }],

    ['PATCH', /^\/api\/admin\/orders\/([\w-]+)$/, async (req, [id]) => {
      requireAdmin(req);
      const o = store.get(id);
      if (!o) throw httpError(404, 'Захиалга олдсонгүй');
      const { status } = await readJson(req);
      if (!STATUSES.includes(status)) throw httpError(400, `status нь ${STATUSES.join(', ')}-ийн нэг байна`);
      return publicOrder(setStatus(o, status));
    }],
  ];

  function requireAdmin(req) {
    const h = req.headers.authorization || '';
    if (!config.adminToken || !safeEqual(h, `Bearer ${config.adminToken}`)) throw httpError(401, 'Unauthorized');
  }

  return async function handler(req, res) {
    const url = new URL(req.url, 'http://x');
    req.query = url.searchParams;
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PATCH, OPTIONS');
    if (req.method === 'OPTIONS') return send(res, 204, null);
    try {
      for (const [method, re, fn] of routes) {
        if (method !== 'ANY' && method !== req.method) continue;
        const m = url.pathname.match(re);
        if (!m) continue;
        const out = await fn(req, m.slice(1));
        const [code, body] = Array.isArray(out) && typeof out[0] === 'number' && out.length === 2 ? out : [200, out];
        return send(res, code, body);
      }
      send(res, 404, { error: 'Not found' });
    } catch (e) {
      const code = e.status || 500;
      if (code >= 500) console.error(e);
      send(res, code, { error: code >= 500 ? 'Серверийн алдаа. Түр хүлээгээд дахин оролдоно уу.' : e.message });
    }
  };
}

// ---------- helpers ----------
function send(res, code, body) {
  if (body === null) { res.writeHead(code); return res.end(); }
  if (typeof body === 'string') {
    res.writeHead(code, { 'Content-Type': 'text/plain; charset=utf-8' });
    return res.end(body);
  }
  res.writeHead(code, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(body));
}
function httpError(status, message) { return Object.assign(new Error(message), { status }); }
function str(v, max) { return String(v ?? '').trim().slice(0, max); }
function safeEqual(a, b) {
  const x = Buffer.from(String(a)), y = Buffer.from(String(b));
  return x.length === y.length && crypto.timingSafeEqual(x, y);
}
async function readJson(req) {
  let size = 0; const chunks = [];
  for await (const c of req) {
    size += c.length;
    if (size > 64 * 1024) throw httpError(413, 'Хүсэлт хэт том');
    chunks.push(c);
  }
  if (!chunks.length) return {};
  try { return JSON.parse(Buffer.concat(chunks).toString('utf8')); } catch { throw httpError(400, 'JSON буруу'); }
}
function loadDotEnv(file) {
  if (!fs.existsSync(file)) return;
  for (const line of fs.readFileSync(file, 'utf8').split('\n')) {
    const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/);
    if (m && process.env[m[1]] === undefined) process.env[m[1]] = m[2].replace(/^["']|["']$/g, '');
  }
}

// ---------- main ----------
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const catalog = JSON.parse(fs.readFileSync(path.join(dir, 'catalog.json'), 'utf8'));
  const store = new OrderStore(path.join(dir, 'data', 'orders.json'));
  const qpay = process.env.QPAY_USERNAME
    ? new QPayClient({
        baseUrl: process.env.QPAY_BASE_URL || 'https://merchant.qpay.mn',
        username: process.env.QPAY_USERNAME,
        password: process.env.QPAY_PASSWORD,
        invoiceCode: process.env.QPAY_INVOICE_CODE,
      })
    : new FakeQPayClient();
  http.createServer(createApp({ catalog, store, qpay })).listen(cfg.port, () => {
    console.log(`CleanMN API: http://localhost:${cfg.port}  (QPay: ${process.env.QPAY_USERNAME ? process.env.QPAY_BASE_URL : 'FAKE'})`);
  });
}
