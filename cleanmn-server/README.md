# CleanMN server

CleanMN апп-д зориулсан захиалга + QPay v2 backend. Гадны сангүй, Node 18+.

```bash
cp .env.example .env   # QPay тохиргоог бөглөнө
npm start              # http://localhost:8080
npm test
```

`QPAY_USERNAME` хоосон бол QPay-г дуурайлгасан **FAKE** горимд ажиллана (2 дахь шалгалтаар төлөгдөнө).
Sandbox-д туршихдаа `.env.example`-ийн `merchant-sandbox.qpay.mn` утгуудыг ашиглана.

## API

| Method | Path | Тайлбар |
|---|---|---|
| GET | `/api/products` | Каталог (`catalog.json`) |
| POST | `/api/orders` | `{items:[{productId,quantity}], delivery}` → захиалга + `token` |
| GET | `/api/orders/:id?token=` | Захиалга, төлөвийн түүх |
| POST | `/api/orders/:id/qpay?token=` | QPay нэхэмжлэх (QR, банкны холбоосууд) |
| POST | `/api/orders/:id/payment-check?token=` | QPay-ээс шалгаж төлөвийг шинэчилнэ |
| GET/POST | `/api/qpay/callback?order=&s=` | QPay-ийн callback |
| GET | `/api/admin/orders?status=` | Админ: бүх захиалга (`Authorization: Bearer $ADMIN_TOKEN`) |
| PATCH | `/api/admin/orders/:id` | Админ: `{status:"preparing"|"delivering"|"delivered"|"cancelled"}` |

Жишээ — захиалгыг хүргэлтэнд гаргах:

```bash
curl -X PATCH localhost:8080/api/admin/orders/<id> \
  -H "Authorization: Bearer $ADMIN_TOKEN" -H "Content-Type: application/json" \
  -d '{"status":"delivering"}'
```

Захиалгууд `data/orders.json`-д хадгалагдана (MVP). Production-д өгөгдлийн сан руу шилжүүлнэ.
