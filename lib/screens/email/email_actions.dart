import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/utils/html_utils.dart';
import '../../data/repositories/misc_repository.dart';
import '../../models/email_model.dart';
import '../../models/label_model.dart';
import '../../providers/email_provider.dart';
import '../../shared/dialogs/snooze_sheet.dart';
import 'package:share_plus/share_plus.dart';

/// Overflow menu used in the reading screen.
class EmailOverflowMenu extends StatelessWidget {
  final EmailModel email;
  final List<EmailModel> thread;
  const EmailOverflowMenu({super.key, required this.email, required this.thread});

  @override
  Widget build(BuildContext context) {
    final p = context.read<EmailProvider>();
    final ids = thread.map((e) => e.id).toList();

    Future<void> done(Future<dynamic> f, String ok, {bool pop = true}) async {
      final r = await f;
      if (!context.mounted) return;
      if (r.ok) {
        if (pop) context.pop();
        context.toast(ok);
      } else {
        context.toast(r.error!.message, error: true);
      }
    }

    return PopupMenuButton<String>(
      tooltip: 'More',
      onSelected: (v) async {
        switch (v) {
          case 'snooze':
            final when = await showSnoozeSheet(context);
            if (when != null && context.mounted) done(p.snooze(ids, when), 'Snoozed');
          case 'important':
            done(p.setImportant(ids, !email.isImportant), email.isImportant ? 'Removed from Important' : 'Marked important', pop: false);
          case 'spam':
            done(p.markSpam(ids), 'Reported as spam');
          case 'label':
            showLabelPicker(context, ids);
          case 'share':
            Share.share(
              'From: ${email.from.address}\nSubject: ${email.subject}\n\n${email.bodyText.isNotEmpty ? email.bodyText : HtmlUtils.toPlain(email.bodyHtml)}',
              subject: email.subject,
            );
          case 'print':
            context.toast('Printing is not available on this device yet.');
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'snooze', child: Text('Snooze')),
        PopupMenuItem(value: 'important', child: Text(email.isImportant ? 'Mark as not important' : 'Mark as important')),
        const PopupMenuItem(value: 'label', child: Text('Change labels')),
        const PopupMenuItem(value: 'spam', child: Text('Report spam')),
        const PopupMenuItem(value: 'share', child: Text('Share')),
      ],
    );
  }
}

/// Bottom sheet to toggle labels on messages.
Future<void> showLabelPicker(BuildContext context, List<String> emailIds) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _LabelPicker(emailIds: emailIds),
  );
}

class _LabelPicker extends StatefulWidget {
  final List<String> emailIds;
  const _LabelPicker({required this.emailIds});
  @override
  State<_LabelPicker> createState() => _LabelPickerState();
}

class _LabelPickerState extends State<_LabelPicker> {
  List<LabelModel>? _labels;
  String? _error;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    MiscRepository.instance.labels().then((r) {
      if (!mounted) return;
      setState(() {
        _labels = r.data;
        _error = r.ok ? null : r.error!.message;
      });
    });
  }

  Future<void> _apply(LabelModel l) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy.add(l.id));
    final r = await MiscRepository.instance.assignLabel(widget.emailIds, l.id, true);
    if (!mounted) return;
    setState(() => _busy.remove(l.id));
    messenger.showSnackBar(SnackBar(content: Text(r.ok ? 'Label "${l.name}" applied' : r.error!.message)));
    if (r.ok) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(alignment: Alignment.centerLeft, child: Text('Label as', style: context.text.titleMedium)),
          ),
          if (_error != null)
            Padding(padding: const EdgeInsets.all(24), child: Text(_error!))
          else if (_labels == null)
            const Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())
          else if (_labels!.isEmpty)
            const Padding(padding: EdgeInsets.all(24), child: Text('You have no labels yet. Create one from the menu.'))
          else
            Flexible(
              child: ListView(shrinkWrap: true, children: [
                for (final l in _labels!)
                  ListTile(
                    leading: Icon(Icons.label_rounded, color: Color(l.colorValue)),
                    title: Text(l.name),
                    trailing: _busy.contains(l.id)
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : null,
                    onTap: () => _apply(l),
                  ),
              ]),
            ),
        ]),
      ),
    );
  }
}
