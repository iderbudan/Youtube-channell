import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../state/cart_provider.dart';
import '../state/orders_provider.dart';
import '../utils/format.dart';
import '../widgets/summary_row.dart';
import '../utils/validators.dart';
import 'payment_screen.dart';

/// Хүргэлтийн хаяг, утас оруулах.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _khoroo = TextEditingController();
  final _address = TextEditingController();
  final _note = TextEditingController();
  String? _district;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final last = context.read<OrdersProvider>().lastDelivery;
    if (last != null) {
      _name.text = last.name;
      _phone.text = last.phone;
      _khoroo.text = last.khoroo;
      _address.text = last.address;
      _district = ulaanbaatarDistricts.contains(last.district) ? last.district : null;
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _khoroo, _address, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final cart = context.read<CartProvider>();
    final orders = context.read<OrdersProvider>();
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _submitting = true);
    try {
      final order = await orders.place(
        cart.toRequest(),
        DeliveryInfo(
          name: _name.text.trim(),
          phone: normalizePhone(_phone.text),
          district: _district!,
          khoroo: _khoroo.text.trim(),
          address: _address.text.trim(),
          note: _note.text.trim(),
        ),
      );
      cart.clear();
      nav.pushReplacement(MaterialPageRoute(builder: (_) => PaymentScreen(order: order)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    const gap = SizedBox(height: 14);
    return Scaffold(
      appBar: AppBar(title: const Text('Хүргэлтийн мэдээлэл')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Хүлээн авагчийн нэр',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => validateRequired(v, 'Нэрээ'),
            ),
            gap,
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                LengthLimitingTextInputFormatter(13),
              ],
              decoration: const InputDecoration(
                labelText: 'Утасны дугаар',
                hintText: '99112233',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: validatePhone,
            ),
            gap,
            DropdownButtonFormField<String>(
              initialValue: _district,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Дүүрэг (Улаанбаатар)',
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
              items: [for (final d in ulaanbaatarDistricts) DropdownMenuItem(value: d, child: Text(d))],
              onChanged: (v) => setState(() => _district = v),
              validator: (v) => v == null ? 'Дүүргээ сонгоно уу' : null,
            ),
            gap,
            TextFormField(
              controller: _khoroo,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
              decoration: const InputDecoration(
                labelText: 'Хороо',
                hintText: '3',
                prefixIcon: Icon(Icons.tag),
              ),
              validator: (v) => validateRequired(v, 'Хороогоо'),
            ),
            gap,
            TextFormField(
              controller: _address,
              maxLines: 2,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Дэлгэрэнгүй хаяг',
                hintText: 'Хотхон, байр, орц, давхар, тоот',
                prefixIcon: Icon(Icons.home_outlined),
              ),
              validator: (v) => validateRequired(v, 'Хаягаа'),
            ),
            gap,
            TextFormField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Нэмэлт тайлбар (заавал биш)',
                hintText: 'Орцны код, хүргэх цаг гэх мэт',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _line('Бараа (${cart.count})', formatMnt(cart.subtotal)),
                    _line('Хүргэлт', cart.deliveryFee == 0 ? 'Үнэгүй' : formatMnt(cart.deliveryFee)),
                    const Divider(),
                    _line('Төлөх дүн', formatMnt(cart.total), bold: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.qr_code_2, size: 32),
              title: Text('Төлбөрийн хэлбэр: QPay'),
              subtitle: Text('Бүх банкны апп-аар QR уншуулж эсвэл шууд төлнө'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: _submitting || cart.isEmpty ? null : _submit,
            child: _submitting
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                : Text('QPay-ээр төлөх · ${formatMnt(cart.total)}'),
          ),
        ),
      ),
    );
  }

  Widget _line(String a, String b, {bool bold = false}) => SummaryRow(a, b, bold: bold);
}
