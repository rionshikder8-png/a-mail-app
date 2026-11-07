import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inbox_provider.dart';

class InboxFilters extends StatelessWidget {
  const InboxFilters({super.key});

  static const _items = [
    (InboxFilter.all, 'All', Icons.inbox_rounded),
    (InboxFilter.unread, 'Unread', Icons.mark_email_unread_outlined),
    (InboxFilter.starred, 'Starred', Icons.star_outline_rounded),
    (InboxFilter.attachments, 'Attachments', Icons.attach_file_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.watch<InboxProvider>();
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final it = _items[i];
          final sel = p.filter == it.$1;
          return ChoiceChip(
            selected: sel,
            showCheckmark: false,
            avatar: Icon(it.$3, size: 16, color: sel ? cs.onPrimary : cs.onSurfaceVariant),
            label: Text(it.$2),
            labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(color: sel ? cs.onPrimary : cs.onSurface),
            selectedColor: cs.primary,
            backgroundColor: cs.surfaceContainerLow,
            side: BorderSide(color: sel ? cs.primary : cs.outlineVariant),
            onSelected: (_) => p.setFilter(it.$1),
          );
        },
      ),
    );
  }
}
