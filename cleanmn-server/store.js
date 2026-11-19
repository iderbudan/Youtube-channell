// Энгийн JSON файл дээрх хадгалалт. Production-д PostgreSQL зэрэг рүү солино.
import fs from 'node:fs';
import path from 'node:path';

export class OrderStore {
  constructor(file) {
    this.file = file;
    this.orders = new Map();
    this.seq = 240000;
    if (file && fs.existsSync(file)) {
      const data = JSON.parse(fs.readFileSync(file, 'utf8'));
      this.seq = data.seq ?? this.seq;
      for (const o of data.orders ?? []) this.orders.set(o.id, o);
    }
  }
  nextNumber() { return `CM-${++this.seq}`; }
  get(id) { return this.orders.get(id); }
  all() { return [...this.orders.values()].sort((a, b) => b.createdAt.localeCompare(a.createdAt)); }
  save(order) {
    this.orders.set(order.id, order);
    this._flush();
    return order;
  }
  _flush() {
    if (!this.file) return;
    fs.mkdirSync(path.dirname(this.file), { recursive: true });
    const tmp = `${this.file}.tmp`;
    fs.writeFileSync(tmp, JSON.stringify({ seq: this.seq, orders: [...this.orders.values()] }, null, 1));
    fs.renameSync(tmp, this.file);
  }
}
