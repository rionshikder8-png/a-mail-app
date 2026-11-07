import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Gmail-style snooze picker. Returns the chosen wake-up time (local).
Future<DateTime?> showSnoozeSheet(BuildContext context) {
  final now = DateTime.now();
  DateTime at(DateTime d, int h) => DateTime(d.year, d.month, d.day, h);
  final laterToday = now.hour < 15 ? at(now, now.hour + 3) : null;
  final tomorrow = at(now.add(const Duration(days: 1)), 8);
  final weekend = at(now.add(Duration(days: (6 - now.weekday) % 7 == 0 ? 7 : (6 - now.weekday) % 7)), 8);
  final nextWeek = at(now.add(Duration(days: (8 - now.weekday) % 7 == 0 ? 7 : (8 - now.weekday) % 7)), 8);
  final f = DateFormat('EEE, h:mm a');

  Widget opt(BuildContext c, IconData i, String t, DateTime d) => ListTile(
        leading: Icon(i),
        title: Text(t),
        trailing: Text(f.format(d), style: Theme.of(c).textTheme.bodySmall),
        onTap: () => Navigator.pop(c, d),
      );

  return showModalBottomSheet<DateTime>(
    context: context,
    builder: (c) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Align(alignment: Alignment.centerLeft, child: Text('Snooze until…', style: Theme.of(c).textTheme.titleMedium)),
        ),
        if (laterToday != null) opt(c, Icons.wb_twilight_rounded, 'Later today', laterToday),
        opt(c, Icons.wb_sunny_outlined, 'Tomorrow', tomorrow),
        opt(c, Icons.weekend_outlined, 'This weekend', weekend),
        opt(c, Icons.next_week_outlined, 'Next week', nextWeek),
        ListTile(
          leading: const Icon(Icons.calendar_month_outlined),
          title: const Text('Pick date & time'),
          onTap: () async {
            final d = await showDatePicker(context: c, initialDate: now, firstDate: now, lastDate: now.add(const Duration(days: 365)));
            if (d == null || !c.mounted) return;
            final t = await showTimePicker(context: c, initialTime: const TimeOfDay(hour: 8, minute: 0));
            if (t == null || !c.mounted) return;
            Navigator.pop(c, DateTime(d.year, d.month, d.day, t.hour, t.minute));
          },
        ),
      ]),
    ),
  );
}

/// Schedule-send picker, same presets.
Future<DateTime?> showScheduleSheet(BuildContext context) {
  final now = DateTime.now();
  DateTime at(DateTime d, int h) => DateTime(d.year, d.month, d.day, h);
  final tomorrowAm = at(now.add(const Duration(days: 1)), 8);
  final tomorrowPm = at(now.add(const Duration(days: 1)), 13);
  final monday = at(now.add(Duration(days: (8 - now.weekday) % 7 == 0 ? 7 : (8 - now.weekday) % 7)), 8);
  final f = DateFormat('MMM d, h:mm a');

  Widget opt(BuildContext c, String t, DateTime d) =>
      ListTile(title: Text(t), trailing: Text(f.format(d), style: Theme.of(c).textTheme.bodySmall), onTap: () => Navigator.pop(c, d));

  return showModalBottomSheet<DateTime>(
    context: context,
    builder: (c) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Align(alignment: Alignment.centerLeft, child: Text('Schedule send', style: Theme.of(c).textTheme.titleMedium)),
        ),
        opt(c, 'Tomorrow morning', tomorrowAm),
        opt(c, 'Tomorrow afternoon', tomorrowPm),
        opt(c, 'Monday morning', monday),
        ListTile(
          leading: const Icon(Icons.calendar_month_outlined),
          title: const Text('Pick date & time'),
          onTap: () async {
            final d = await showDatePicker(context: c, initialDate: now, firstDate: now, lastDate: now.add(const Duration(days: 365)));
            if (d == null || !c.mounted) return;
            final t = await showTimePicker(context: c, initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))));
            if (t == null || !c.mounted) return;
            final dt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
            if (dt.isBefore(now)) return;
            Navigator.pop(c, dt);
          },
        ),
      ]),
    ),
  );
}
