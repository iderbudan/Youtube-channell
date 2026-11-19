/// Монгол гар утасны дугаар: 8 оронтой, 6/7/8/9-өөр эхэлнэ.
final _phoneRe = RegExp(r'^[6-9]\d{7}$');

String normalizePhone(String input) {
  var p = input.replaceAll(RegExp(r'[\s\-()]'), '');
  if (p.startsWith('+976')) p = p.substring(4);
  if (p.startsWith('976') && p.length == 11) p = p.substring(3);
  return p;
}

String? validatePhone(String? v) {
  final p = normalizePhone(v ?? '');
  if (p.isEmpty) return 'Утасны дугаараа оруулна уу';
  if (!_phoneRe.hasMatch(p)) return '8 оронтой зөв дугаар оруулна уу';
  return null;
}

String? validateRequired(String? v, String field) =>
    (v == null || v.trim().isEmpty) ? '$field оруулна уу' : null;

const ulaanbaatarDistricts = [
  'Баянгол',
  'Баянзүрх',
  'Сонгинохайрхан',
  'Сүхбаатар',
  'Хан-Уул',
  'Чингэлтэй',
  'Налайх',
  'Багануур',
  'Багахангай',
];
