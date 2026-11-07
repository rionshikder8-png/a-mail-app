import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/helpers/address_parser.dart';
import '../../core/utils/validators.dart';
import '../../models/contact_model.dart';
import '../../models/email_model.dart';
import '../../navigation/route_names.dart';
import '../../shared/widgets/sender_avatar.dart';

/// Chip-style multi-recipient input with contact suggestions.
class RecipientField extends StatefulWidget {
  final String label;
  final List<EmailAddress> recipients;
  final List<ContactModel> contacts;
  final ValueChanged<List<EmailAddress>> onChanged;
  final Widget? trailing;

  const RecipientField({
    super.key,
    required this.label,
    required this.recipients,
    required this.contacts,
    required this.onChanged,
    this.trailing,
  });

  @override
  State<RecipientField> createState() => _RecipientFieldState();
}

class _RecipientFieldState extends State<RecipientField> {
  final _c = TextEditingController();
  final _f = FocusNode();

  @override
  void initState() {
    super.initState();
    _f.addListener(() {
      if (!_f.hasFocus) _commit();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _c.dispose();
    _f.dispose();
    super.dispose();
  }

  void _commit() {
    final txt = _c.text.trim();
    if (txt.isEmpty) return;
    final parsed = AddressParser.parse(txt);
    final next = [...widget.recipients];
    for (final p in parsed) {
      if (!next.contains(p)) next.add(p);
    }
    _c.clear();
    widget.onChanged(next);
  }

  void _add(EmailAddress a) {
    if (!widget.recipients.contains(a)) widget.onChanged([...widget.recipients, a]);
    _c.clear();
    setState(() {});
  }

  List<ContactModel> get _suggestions {
    final q = _c.text.trim().toLowerCase();
    if (q.isEmpty || !_f.hasFocus) return [];
    return widget.contacts
        .where((c) => c.name.toLowerCase().contains(q) || c.email.toLowerCase().contains(q))
        .where((c) => !widget.recipients.contains(EmailAddress(address: c.email)))
        .take(4)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final sugg = _suggestions;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 48,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(widget.label, style: context.text.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            ),
          ),
          Expanded(
            child: Wrap(spacing: 6, runSpacing: 2, crossAxisAlignment: WrapCrossAlignment.center, children: [
              for (final r in widget.recipients)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: InputChip(
                    avatar: SenderAvatar(name: r.display, seed: r.address, size: 24),
                    label: Text(r.display, style: context.text.bodyMedium),
                    side: BorderSide(color: Validators.isEmail(r.address) ? cs.outlineVariant : cs.error),
                    backgroundColor: Validators.isEmail(r.address) ? null : cs.error.withValues(alpha: 0.08),
                    onDeleted: () => widget.onChanged(widget.recipients.where((e) => e != r).toList()),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 120, maxWidth: 260),
                child: IntrinsicWidth(
                  child: TextField(
                    controller: _c,
                    focusNode: _f,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    onChanged: (v) {
                      if (v.endsWith(',') || v.endsWith(' ') || v.endsWith(';')) {
                        _c.text = v.substring(0, v.length - 1);
                        _commit();
                      }
                      setState(() {});
                    },
                    onSubmitted: (_) => _commit(),
                    decoration: const InputDecoration(
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined, size: 20),
            tooltip: 'Pick from contacts',
            onPressed: () async {
              final picked = await context.push<ContactModel>(Routes.contacts, extra: 'pick');
              if (picked != null) _add(EmailAddress(name: picked.name, address: picked.email));
            },
          ),
          if (widget.trailing != null) widget.trailing!,
        ]),
      ),
      if (sugg.isNotEmpty)
        Container(
          margin: const EdgeInsets.fromLTRB(64, 0, 16, 6),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(children: [
            for (final s in sugg)
              ListTile(
                dense: true,
                leading: SenderAvatar(name: s.name, seed: s.email, size: 32),
                title: Text(s.name),
                subtitle: Text(s.email),
                onTap: () => _add(EmailAddress(name: s.name, address: s.email)),
              ),
          ]),
        ),
      Divider(height: 1, color: cs.outlineVariant),
    ]);
  }
}
