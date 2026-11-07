import 'package:intl/intl.dart';

class DateFmt {
  DateFmt._();

  /// Newer ICU data inserts U+202F before AM/PM; normalise to a plain space.
  static String _n(String v) => v.replaceAll('\u202f', ' ').replaceAll('\u00a0', ' ');

  /// Gmail-style list timestamp: time today, "Mon d" this year, "d/m/yy" older.
  static String list(DateTime d, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final l = d.toLocal();
    if (l.year == n.year && l.month == n.month && l.day == n.day) return _n(DateFormat.jm().format(l));
    if (l.year == n.year) return DateFormat.MMMd().format(l);
    return DateFormat('dd/MM/yy').format(l);
  }

  static String full(DateTime d) => _n(DateFormat('EEE, MMM d, y • h:mm a').format(d.toLocal()));

  static String short(DateTime d) => _n(DateFormat('MMM d, h:mm a').format(d.toLocal()));

  static String relative(DateTime d, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final diff = n.difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays < 7) return '${diff.inDays} d ago';
    return list(d, now: n);
  }

  static String dayHeader(DateTime d, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final l = d.toLocal();
    final a = DateTime(n.year, n.month, n.day);
    final b = DateTime(l.year, l.month, l.day);
    final diff = a.difference(b).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('EEEE, MMM d').format(l);
  }
}
