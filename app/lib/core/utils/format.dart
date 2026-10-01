/// Small display helpers (English UI, km, Pakistan time on the phone's clock).
library;

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// 123456 -> "123,456"
String formatThousands(int n) {
  final s = n.abs().toString();
  final out = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
    out.write(s[i]);
  }
  return out.toString();
}

String formatKm(int km) => '${formatThousands(km)} km';

String _two(int n) => n.toString().padLeft(2, '0');

/// "14:05"
String formatTime(DateTime t) {
  final l = t.toLocal();
  return '${_two(l.hour)}:${_two(l.minute)}';
}

/// "Today 14:05", "Yesterday 09:30" or "3 Oct 14:05".
String formatWhen(DateTime t, {DateTime? now}) {
  final l = t.toLocal();
  final n = (now ?? DateTime.now()).toLocal();
  final day = DateTime(l.year, l.month, l.day);
  final today = DateTime(n.year, n.month, n.day);
  final diff = today.difference(day).inDays;
  final time = formatTime(l);
  if (diff == 0) return 'Today $time';
  if (diff == 1) return 'Yesterday $time';
  return '${l.day} ${_months[l.month - 1]} $time';
}
