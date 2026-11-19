// QPay Merchant API v2 клиент (https://developer.qpay.mn)
// Нууц түлхүүр зөвхөн сервер дээр байна — мобайл апп руу хэзээ ч дамжуулахгүй.

export class QPayClient {
  constructor({ baseUrl, username, password, invoiceCode }) {
    this.baseUrl = baseUrl.replace(/\/$/, '');
    this.username = username;
    this.password = password;
    this.invoiceCode = invoiceCode;
    this._token = null;
    this._tokenExp = 0;
  }

  async _auth() {
    if (this._token && Date.now() < this._tokenExp - 60_000) return this._token;
    const res = await fetch(`${this.baseUrl}/v2/auth/token`, {
      method: 'POST',
      headers: {
        Authorization: 'Basic ' + Buffer.from(`${this.username}:${this.password}`).toString('base64'),
      },
    });
    if (!res.ok) throw new Error(`QPay auth амжилтгүй: ${res.status}`);
    const j = await res.json();
    this._token = j.access_token;
    // expires_in нь unix секунд эсвэл үргэлжлэх хугацаа байж болно
    const exp = Number(j.expires_in) || 0;
    this._tokenExp = exp > 1e9 ? exp * 1000 : Date.now() + (exp || 3600) * 1000;
    return this._token;
  }

  async _call(path, body) {
    const token = await this._auth();
    const res = await fetch(`${this.baseUrl}${path}`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    const text = await res.text();
    if (!res.ok) throw new Error(`QPay ${path} алдаа ${res.status}: ${text.slice(0, 300)}`);
    return text ? JSON.parse(text) : {};
  }

  /** Нэхэмжлэх үүсгэнэ. */
  async createInvoice({ senderInvoiceNo, receiverCode, description, amount, callbackUrl }) {
    const j = await this._call('/v2/invoice', {
      invoice_code: this.invoiceCode,
      sender_invoice_no: senderInvoiceNo,
      invoice_receiver_code: receiverCode,
      invoice_description: description,
      amount,
      callback_url: callbackUrl,
    });
    return {
      invoiceId: j.invoice_id,
      qrText: j.qr_text,
      amount,
      shortUrl: j.qPay_shortUrl ?? null,
      urls: (j.urls ?? []).map((u) => ({
        name: u.name, description: u.description, logo: u.logo, link: u.link,
      })),
    };
  }

  /** Нэхэмжлэхийн төлбөр орсон эсэхийг шалгана. Төлөгдсөн дүнг буцаана. */
  async paidAmount(invoiceId) {
    const j = await this._call('/v2/payment/check', {
      object_type: 'INVOICE',
      object_id: invoiceId,
      offset: { page_number: 1, page_limit: 100 },
    });
    const rows = (j.rows ?? []).filter((r) => r.payment_status === 'PAID');
    return rows.reduce((s, r) => s + Number(r.payment_amount || 0), 0) || Number(j.paid_amount || 0);
  }
}

/** QPay гэрээгүй үед локал хөгжүүлэлтэд — 2 дахь шалгалтаар төлөгдсөнд тооцно. */
export class FakeQPayClient {
  constructor() { this.checks = new Map(); this.amounts = new Map(); }
  async createInvoice({ senderInvoiceNo, amount }) {
    this.amounts.set(`FAKE-${senderInvoiceNo}`, amount);
    return {
      invoiceId: `FAKE-${senderInvoiceNo}`,
      qrText: `CLEANMN-FAKE|${senderInvoiceNo}|${amount}`,
      amount,
      shortUrl: null,
      urls: [
        { name: 'khanbank', description: 'Хаан банк', logo: null, link: 'khanbank://q?qPay_QRcode=fake' },
        { name: 'xacbank', description: 'Хас банк', logo: null, link: 'xacbank://q?qPay_QRcode=fake' },
      ],
    };
  }
  async paidAmount(invoiceId) {
    const n = (this.checks.get(invoiceId) ?? 0) + 1;
    this.checks.set(invoiceId, n);
    return n >= 2 ? (this.amounts.get(invoiceId) ?? 0) : 0;
  }
}
