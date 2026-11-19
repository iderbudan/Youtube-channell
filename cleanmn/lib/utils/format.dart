/// 12500 -> "12,500₮"
String formatMnt(int amount) {
  final s = amount.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '${amount < 0 ? '-' : ''}$buf₮';
}

String _two(int n) => n.toString().padLeft(2, '0');

/// 2026-11-19 14:05
String formatDateTime(DateTime d) =>
    '${d.year}-${_two(d.month)}-${_two(d.day)} ${_two(d.hour)}:${_two(d.minute)}';
