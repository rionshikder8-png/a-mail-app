import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/extensions/context_extensions.dart';
import '../../providers/inbox_provider.dart';
import '../../shared/components/primary_button.dart';
import '../../shared/widgets/app_text_field.dart';

class AdvancedSearchScreen extends StatefulWidget {
  const AdvancedSearchScreen({super.key});
  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  late final InboxProvider _p = context.read<InboxProvider>();
  late final _from = TextEditingController(text: _p.query.from);
  late final _to = TextEditingController(text: _p.query.to);
  late final _subject = TextEditingController(text: _p.query.subject);
  late final _words = TextEditingController(text: _p.query.text);
  late bool _att = _p.query.hasAttachment;
  late String _folder = _p.query.folder;
  DateTime? _after;
  DateTime? _before;

  static const _folders = {
    'all': 'All mail',
    'inbox': 'Inbox',
    'sent': 'Sent',
    'drafts': 'Drafts',
    'starred': 'Starred',
    'spam': 'Spam',
    'trash': 'Trash',
  };

  @override
  void initState() {
    super.initState();
    _after = _p.query.after;
    _before = _p.query.before;
  }

  @override
  void dispose() {
    for (final c in [_from, _to, _subject, _words]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick(bool after) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: (after ? _after : _before) ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (d != null) setState(() => after ? _after = d : _before = d);
  }

  void _apply() {
    final q = _p.query;
    q
      ..from = _from.text.trim()
      ..to = _to.text.trim()
      ..subject = _subject.text.trim()
      ..text = _words.text.trim()
      ..hasAttachment = _att
      ..folder = _folder
      ..after = _after
      ..before = _before;
    _p.search();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final f = DateFormat.yMMMd();
    return Scaffold(
      appBar: AppBar(title: const Text('Advanced search'), actions: [
        TextButton(
          onPressed: () {
            _p.clearSearch();
            context.pop();
          },
          child: const Text('Reset'),
        ),
      ]),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        AppTextField(controller: _from, label: 'From', prefixIcon: Icons.person_outline_rounded, keyboard: TextInputType.emailAddress),
        const SizedBox(height: 14),
        AppTextField(controller: _to, label: 'To', prefixIcon: Icons.send_outlined, keyboard: TextInputType.emailAddress),
        const SizedBox(height: 14),
        AppTextField(controller: _subject, label: 'Subject', prefixIcon: Icons.subject_rounded),
        const SizedBox(height: 14),
        AppTextField(controller: _words, label: 'Has the words', prefixIcon: Icons.search_rounded),
        const SizedBox(height: 18),
        DropdownButtonFormField<String>(
          initialValue: _folders.containsKey(_folder) ? _folder : 'all',
          decoration: const InputDecoration(labelText: 'Search in', prefixIcon: Icon(Icons.folder_open_rounded, size: 20)),
          items: [for (final e in _folders.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
          onChanged: (v) => setState(() => _folder = v ?? 'all'),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: () => _pick(true),
              icon: const Icon(Icons.event_outlined, size: 18),
              label: Text(_after == null ? 'After' : f.format(_after!)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: () => _pick(false),
              icon: const Icon(Icons.event_outlined, size: 18),
              label: Text(_before == null ? 'Before' : f.format(_before!)),
            ),
          ),
        ]),
        const SizedBox(height: 6),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _att,
          onChanged: (v) => setState(() => _att = v),
          title: const Text('Has attachment'),
        ),
        const SizedBox(height: 16),
        PrimaryButton(label: 'Search', icon: Icons.search_rounded, onPressed: _apply),
        const SizedBox(height: 8),
        Text('Searches run on the A-Mail server once it is connected.', style: context.text.bodySmall),
      ]),
    );
  }
}
