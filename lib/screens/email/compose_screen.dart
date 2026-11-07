import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_config.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/helpers/address_parser.dart';
import '../../core/services/file_service.dart';
import '../../core/services/local_database.dart';
import '../../core/utils/rich_text_codec.dart';
import '../../core/utils/html_utils.dart';
import '../../data/datasources/remote_datasource.dart';
import '../../data/repositories/email_repository.dart';
import '../../data/repositories/misc_repository.dart';
import '../../models/attachment_model.dart';
import '../../models/contact_model.dart';
import '../../models/email_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../shared/dialogs/dialogs.dart';
import '../../shared/dialogs/snooze_sheet.dart';
import 'attachment_tile.dart';
import 'recipient_field.dart';
import 'rich_text_editor.dart';

/// Shared by Compose, Reply and Forward (they pass initial values).
class ComposeScreen extends StatefulWidget {
  final List<EmailAddress>? prefilledTo;
  final List<EmailAddress>? prefilledCc;
  final String? initialSubject;
  final String? initialBody; // markup
  final String? inReplyToId;
  final String? threadId;
  final String title;
  final EmailModel? draft;
  final List<AttachmentModel> initialAttachments;

  const ComposeScreen({
    super.key,
    this.prefilledTo,
    this.prefilledCc,
    this.initialSubject,
    this.initialBody,
    this.inReplyToId,
    this.threadId,
    this.title = 'Compose',
    this.draft,
    this.initialAttachments = const [],
  });

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  late List<EmailAddress> _to = [...?widget.prefilledTo];
  late List<EmailAddress> _cc = [...?widget.prefilledCc];
  final List<EmailAddress> _bcc = [];
  bool _showCcBcc = false;
  final _subject = TextEditingController();
  final _body = RichTextController();
  final List<AttachmentModel> _attachments = [];
  final _uploaded = <String, AttachmentModel>{}; // local id -> server attachment
  List<ContactModel> _contacts = [];
  Timer? _autosave;
  String? _draftId;
  String _savedState = '';
  bool _sending = false;
  DateTime? _lastSaved;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final d = widget.draft;
    if (d != null) {
      _to = [...d.to];
      _cc = [...d.cc];
      _subject.text = d.subject;
      _body.text = d.bodyText.isNotEmpty ? d.bodyText : HtmlUtils.toPlain(d.bodyHtml);
      _draftId = d.id;
      _attachments.addAll(d.attachments);
    } else {
      _subject.text = widget.initialSubject ?? '';
      final sig = context.read<SettingsProvider>();
      final signature = sig.signatureEnabled && sig.signature.trim().isNotEmpty ? '\n\n-- \n${sig.signature.trim()}' : '';
      _body.text = '${widget.initialBody ?? ''}$signature';
      _body.selection = const TextSelection.collapsed(offset: 0);
    }
    _attachments.addAll(widget.initialAttachments);
    _showCcBcc = _cc.isNotEmpty;
    for (final c in [_subject, _body]) {
      c.addListener(_markDirty);
    }
    MiscRepository.instance.contacts().then((r) {
      if (mounted && r.ok) setState(() => _contacts = r.data ?? []);
    });
    _savedState = _fingerprint();
  }

  String _fingerprint() =>
      '${_to.map((e) => e.address)}|${_cc.map((e) => e.address)}|${_bcc.map((e) => e.address)}|${_subject.text}|${_body.text}|${_attachments.length}';

  void _markDirty() {
    _dirty = true;
    _autosave?.cancel();
    _autosave = Timer(AppConfig.draftAutosave, _saveDraft);
  }

  bool get _isEmpty => _to.isEmpty && _cc.isEmpty && _bcc.isEmpty && _subject.text.trim().isEmpty && _body.text.trim().isEmpty && _attachments.isEmpty;

  Map<String, dynamic> _payload({bool forSend = false}) {
    final me = context.read<AuthProvider>().user;
    return {
      if (_draftId != null) 'draft_id': _draftId,
      if (widget.inReplyToId != null) 'in_reply_to': widget.inReplyToId,
      if (widget.threadId != null) 'thread_id': widget.threadId,
      'from': me?.address,
      'to': _to.map((e) => e.toJson()).toList(),
      'cc': _cc.map((e) => e.toJson()).toList(),
      'bcc': _bcc.map((e) => e.toJson()).toList(),
      'subject': _subject.text.trim(),
      'body_html': RichTextCodec.toHtml(_body.text),
      'body_text': RichTextCodec.toPlain(_body.text),
      'attachment_ids': _attachments.map((a) => _uploaded[a.id]?.id ?? a.id).where((id) => !id.startsWith('local-')).toList(),
    };
  }

  Future<void> _saveDraft() async {
    if (_isEmpty || _sending) return;
    final fp = _fingerprint();
    if (fp == _savedState) return;
    _savedState = fp;
    final id = _draftId ?? 'draft-${DateTime.now().microsecondsSinceEpoch}';
    // Local first (works offline), then best-effort server sync.
    await LocalDatabase.instance.saveDraft(id, {..._payload(), 'local_id': id});
    final r = await RemoteDataSource.instance.saveDraft(_payload());
    if (r.ok && r.data != null) {
      _draftId = r.data;
      await LocalDatabase.instance.deleteDraft(id);
    } else {
      _draftId ??= id;
    }
    if (mounted) setState(() => _lastSaved = DateTime.now());
  }

  Future<bool> _ensureUploaded() async {
    for (final a in _attachments.where((a) => a.localPath != null && !_uploaded.containsKey(a.id))) {
      final r = await RemoteDataSource.instance.uploadAttachment(a.localPath!, a.fileName);
      if (!r.ok) {
        if (mounted) context.toast('Couldn\'t upload ${a.fileName}: ${r.error!.message}', error: true);
        return false;
      }
      _uploaded[a.id] = r.data!;
    }
    return true;
  }

  String? _validate() {
    if (_to.isEmpty && _cc.isEmpty && _bcc.isEmpty) return 'Add at least one recipient';
    if (!AddressParser.allValid([..._to, ..._cc, ..._bcc])) return 'One or more addresses are not valid';
    return null;
  }

  Future<void> _send() async {
    final err = _validate();
    if (err != null) return context.toast(err, error: true);
    if (_subject.text.trim().isEmpty && _body.text.trim().isEmpty) {
      final go = await confirmDialog(context, title: 'Send empty message?', message: 'This message has no subject or body.', confirmLabel: 'Send');
      if (!go || !mounted) return;
    } else if (_subject.text.trim().isEmpty) {
      final go = await confirmDialog(context, title: 'Send without subject?', message: 'This message has no subject.', confirmLabel: 'Send anyway');
      if (!go || !mounted) return;
    }
    _autosave?.cancel();
    final nav = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final payloadBuilder = _payload;
    setState(() => _sending = true);
    if (!await _ensureUploaded()) {
      setState(() => _sending = false);
      return;
    }
    final payload = payloadBuilder();
    nav.pop();
    _undoableSend(messenger, payload);
  }

  /// Gmail-style "Sending… Undo" window; the request is only made when the window closes.
  static void _undoableSend(ScaffoldMessengerState m, Map<String, dynamic> payload) {
    var cancelled = false;
    m.hideCurrentSnackBar();
    final c = m.showSnackBar(SnackBar(
      content: const Text('Sending…'),
      duration: AppConfig.undoSendWindow,
      action: SnackBarAction(label: 'Undo', onPressed: () => cancelled = true),
    ));
    c.closed.then((_) async {
      if (cancelled) {
        m.showSnackBar(const SnackBar(content: Text('Send cancelled. Message saved to Drafts.')));
        await RemoteDataSource.instance.saveDraft(payload);
        return;
      }
      final r = await EmailRepository.instance.send(payload);
      m.showSnackBar(SnackBar(
        content: Text(r.ok ? 'Message sent' : 'Not sent: ${r.error!.message}'),
        backgroundColor: r.ok ? null : Colors.red.shade700,
      ));
      if (!r.ok) await RemoteDataSource.instance.saveDraft(payload);
    });
  }

  Future<void> _schedule() async {
    final err = _validate();
    if (err != null) return context.toast(err, error: true);
    final when = await showScheduleSheet(context);
    if (when == null || !mounted) return;
    setState(() => _sending = true);
    if (!await _ensureUploaded()) {
      setState(() => _sending = false);
      return;
    }
    final r = await EmailRepository.instance.schedule({..._payload(), 'scheduled_at': when.toUtc().toIso8601String()});
    if (!mounted) return;
    setState(() => _sending = false);
    if (r.ok) {
      _dirty = false;
      final m = ScaffoldMessenger.of(context);
      context.pop();
      m.showSnackBar(const SnackBar(content: Text('Message scheduled')));
    } else {
      context.toast(r.error!.message, error: true);
    }
  }

  Future<void> _attach() async {
    final res = await FileService.instance.pickAttachments();
    if (!mounted) return;
    if (res.rejected.isNotEmpty) {
      context.toast('${res.rejected.join(', ')} exceeds the ${AppConfig.maxAttachmentBytes ~/ (1024 * 1024)} MB limit', error: true);
    }
    if (res.files.isNotEmpty) {
      setState(() => _attachments.addAll(res.files));
      _markDirty();
    }
  }

  Future<void> _insertImage() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) return;
    final len = await x.length();
    if (len > AppConfig.maxAttachmentBytes) {
      if (mounted) context.toast('Image is larger than the attachment limit', error: true);
      return;
    }
    setState(() => _attachments.add(AttachmentModel(
          id: 'local-${DateTime.now().microsecondsSinceEpoch}',
          fileName: x.name,
          mimeType: x.mimeType ?? 'image/jpeg',
          sizeBytes: len,
          localPath: x.path,
        )));
    _markDirty();
  }

  Future<void> _discard() async {
    final ok = await confirmDialog(context, title: 'Discard draft?', message: 'This message will be deleted.', confirmLabel: 'Discard', destructive: true);
    if (!ok || !mounted) return;
    _dirty = false;
    if (_draftId != null) await LocalDatabase.instance.deleteDraft(_draftId!);
    if (mounted) context.pop();
  }

  Future<void> _manualSave() async {
    await _saveDraft();
    if (mounted) context.toast('Draft saved');
  }

  Future<bool> _onBack() async {
    if (_isEmpty || !_dirty && widget.draft != null) return true;
    _autosave?.cancel();
    await _saveDraft();
    if (mounted && !_isEmpty) context.toast('Draft saved');
    return true;
  }

  @override
  void dispose() {
    _autosave?.cancel();
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final me = context.watch<AuthProvider>().user;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = GoRouter.of(context);
        await _onBack();
        if (nav.canPop()) nav.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Close',
            onPressed: () async {
              final nav = GoRouter.of(context);
              await _onBack();
              if (nav.canPop()) nav.pop();
            },
          ),
          title: Text(widget.title, style: context.text.titleLarge),
          actions: [
            if (_lastSaved != null)
              Center(child: Padding(padding: const EdgeInsets.only(right: 4), child: Text('Saved', style: context.text.bodySmall))),
            IconButton(
              tooltip: 'Send',
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.send_rounded, color: cs.primary),
            ),
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'schedule') _schedule();
                if (v == 'discard') {
                  _discard();
                }
                if (v == 'draft') {
                  _manualSave();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'schedule', child: Text('Schedule send')),
                PopupMenuItem(value: 'draft', child: Text('Save draft')),
                PopupMenuItem(value: 'discard', child: Text('Discard')),
              ],
            ),
          ],
        ),
        body: Column(children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                _FromRow(address: me?.address ?? ''),
                RecipientField(
                  label: 'To',
                  recipients: _to,
                  contacts: _contacts,
                  onChanged: (l) {
                    setState(() => _to = l);
                    _markDirty();
                  },
                  trailing: IconButton(
                    icon: Icon(_showCcBcc ? Icons.expand_less_rounded : Icons.expand_more_rounded),
                    tooltip: 'Cc / Bcc',
                    onPressed: () => setState(() => _showCcBcc = !_showCcBcc),
                  ),
                ),
                if (_showCcBcc) ...[
                  RecipientField(label: 'Cc', recipients: _cc, contacts: _contacts, onChanged: (l) {
                    setState(() => _cc = l);
                    _markDirty();
                  }),
                  RecipientField(label: 'Bcc', recipients: _bcc, contacts: _contacts, onChanged: (l) {
                    setState(() => _bcc..clear()..addAll(l));
                    _markDirty();
                  }),
                ],
                Divider(height: 1, color: cs.outlineVariant),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _subject,
                    textCapitalization: TextCapitalization.sentences,
                    style: context.text.titleMedium,
                    decoration: const InputDecoration(
                      hintText: 'Subject',
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                Divider(height: 1, color: cs.outlineVariant),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _body,
                    maxLines: null,
                    minLines: 10,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    style: context.text.bodyLarge?.copyWith(height: 1.5),
                    decoration: const InputDecoration(
                      hintText: 'Compose email',
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                if (_attachments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: Column(children: [
                      for (final a in _attachments)
                        AttachmentTile(
                          attachment: a,
                          onRemove: () {
                            setState(() => _attachments.remove(a));
                            _markDirty();
                          },
                        ),
                    ]),
                  ),
              ],
            ),
          ),
          SafeArea(top: false, child: RichTextToolbar(controller: _body, onAttach: _attach, onImage: _insertImage)),
        ]),
      ),
    );
  }
}

class _FromRow extends StatelessWidget {
  final String address;
  const _FromRow({required this.address});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        SizedBox(width: 48, child: Text('From', style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant))),
        Expanded(child: Text(address, style: context.text.bodyLarge)),
      ]),
    );
  }
}
