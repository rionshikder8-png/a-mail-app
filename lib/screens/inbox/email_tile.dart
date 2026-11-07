import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/date_utils.dart';
import '../../models/email_model.dart';
import '../../models/label_model.dart';
import '../../shared/widgets/sender_avatar.dart';

class EmailTile extends StatelessWidget {
  final EmailModel email;
  final bool selected;
  final bool selectionMode;
  final bool compact;
  final List<LabelModel> labels;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onToggleStar;
  final VoidCallback onAvatarTap;

  const EmailTile({
    super.key,
    required this.email,
    required this.selected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onToggleStar,
    required this.onAvatarTap,
    this.compact = false,
    this.labels = const [],
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final unread = !email.isRead;
    final weight = unread ? FontWeight.w700 : FontWeight.w400;
    final subjectColor = unread ? cs.onSurface : cs.onSurfaceVariant;
    final bg = selected ? cs.primary.withValues(alpha: 0.10) : (unread ? cs.surface : cs.surface);
    final tileLabels = labels.where((l) => email.labelIds.contains(l.id)).take(2).toList();
    final sender = email.threadCount > 1 ? '${email.from.display}  ${email.threadCount}' : email.from.display;

    return Material(
      color: bg,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, compact ? 8 : 12, 8, compact ? 8 : 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // unread dot gutter
            SizedBox(
              width: 8,
              child: unread
                  ? Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: Container(width: 7, height: 7, decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle)),
                    )
                  : null,
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onAvatarTap,
              child: SenderAvatar(name: email.from.display, seed: email.from.address, selected: selected, size: compact ? 36 : 42),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(sender,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyLarge?.copyWith(fontWeight: weight, color: cs.onSurface)),
                  ),
                  if (email.isImportant)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.label_important_rounded, size: 16, color: AColors.brandOrange),
                    ),
                  if (email.hasAttachments)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(Icons.attach_file_rounded, size: 16, color: cs.onSurfaceVariant),
                    ),
                  Text(DateFmt.list(email.date),
                      style: tt.bodySmall?.copyWith(fontWeight: unread ? FontWeight.w700 : FontWeight.w400, color: unread ? cs.onSurface : cs.onSurfaceVariant)),
                ]),
                const SizedBox(height: 2),
                Text(email.subject.isEmpty ? '(no subject)' : email.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodyMedium?.copyWith(fontWeight: weight, color: subjectColor)),
                const SizedBox(height: 2),
                Row(children: [
                  Expanded(
                    child: Text(email.snippet,
                        maxLines: compact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
                  ),
                  SizedBox(
                    width: 40,
                    height: 36,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      tooltip: email.isStarred ? 'Unstar' : 'Star',
                      onPressed: onToggleStar,
                      icon: Icon(
                        email.isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: email.isStarred ? AColors.star : cs.onSurfaceVariant,
                        size: 22,
                      ),
                    ),
                  ),
                ]),
                if (tileLabels.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Wrap(spacing: 6, runSpacing: 4, children: [
                      for (final l in tileLabels) LabelChip(label: l),
                    ]),
                  ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class LabelChip extends StatelessWidget {
  final LabelModel label;
  const LabelChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = Color(label.colorValue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(6),
        border: Border(left: BorderSide(color: c, width: 3)),
      ),
      child: Text(label.name, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: c, fontWeight: FontWeight.w600)),
    );
  }
}
