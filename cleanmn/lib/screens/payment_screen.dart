import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/order.dart';
import '../state/orders_provider.dart';
import '../utils/format.dart';
import 'order_detail_screen.dart';

/// QPay төлбөр: QR код + банкны апп-ын холбоос + автомат шалгалт.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.order});
  final Order order;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with WidgetsBindingObserver {
  QPayInvoice? _invoice;
  String? _error;
  bool _checking = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInvoice();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    super.dispose();
  }

  /// Банкны апп-аас буцаж ирэхэд шууд шалгана.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _invoice != null) _check(silent: true);
  }

  Future<void> _loadInvoice() async {
    setState(() => _error = null);
    try {
      final inv = await context.read<OrdersProvider>().invoiceFor(widget.order);
      if (!mounted) return;
      setState(() => _invoice = inv);
      _poll = Timer.periodic(const Duration(seconds: 5), (_) => _check(silent: true));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _check({bool silent = false}) async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final paid = await context.read<OrdersProvider>().checkPayment(widget.order);
      if (!mounted) return;
      if (paid) {
        _poll?.cancel();
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (c) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 56),
            title: const Text('Төлбөр амжилттай'),
            content: Text('Захиалга ${widget.order.number} баталгаажлаа. Бид удахгүй хүргэнэ.'),
            actions: [FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Захиалга харах'))],
          ),
        );
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: widget.order.id)));
      } else if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Төлбөр хараахан орж ирээгүй байна. Түр хүлээгээд дахин шалгана уу.')));
      }
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _openBank(BankLink b) async {
    final ok = await launchUrl(Uri.parse(b.link), mode: LaunchMode.externalApplication)
        .catchError((_) => false);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${b.name} апп суулгаагүй байна')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inv = _invoice;
    return Scaffold(
      appBar: AppBar(title: const Text('QPay төлбөр')),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.tonal(onPressed: _loadInvoice, child: const Text('Дахин оролдох')),
                ]),
              ),
            )
          : inv == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(padding: const EdgeInsets.all(16), children: [
                  Text('Захиалга ${widget.order.number}',
                      textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
                  Text(formatMnt(inv.amount),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                      ),
                      child: QrImageView(data: inv.qrText, size: 220, backgroundColor: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Банкны аппаараа QR кодыг уншуулна уу',
                      textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                  if (inv.bankLinks.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('Эсвэл банкаа сонгоод шууд төлөх', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.1,
                      children: [for (final b in inv.bankLinks) _BankTile(bank: b, onTap: () => _openBank(b))],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text('Төлбөрийг автоматаар шалгаж байна…', style: theme.textTheme.bodySmall),
                    ),
                  ]),
                ]),
      bottomNavigationBar: inv == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  onPressed: _checking ? null : () => _check(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Төлбөр шалгах'),
                ),
              ),
            ),
    );
  }
}

class _BankTile extends StatelessWidget {
  const _BankTile({required this.bank, required this.onTap});
  final BankLink bank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            bank.logo != null
                ? Image.network(bank.logo!, width: 36, height: 36,
                    errorBuilder: (_, _, _) => const Icon(Icons.account_balance))
                : Icon(Icons.account_balance, color: scheme.primary),
            const SizedBox(height: 6),
            Text(bank.name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11)),
          ]),
        ),
      ),
    );
  }
}
