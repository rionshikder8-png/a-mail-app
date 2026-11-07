import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/utils/validators.dart';
import '../../data/repositories/misc_repository.dart';
import '../../models/contact_model.dart';
import '../../models/email_model.dart';
import '../../navigation/app_router.dart';
import '../../navigation/route_names.dart';
import '../../shared/components/primary_button.dart';
import '../../shared/dialogs/dialogs.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/sender_avatar.dart';

class ContactDetailsScreen extends StatefulWidget {
  final ContactModel? contact;
  const ContactDetailsScreen({super.key, this.contact});
  @override
  State<ContactDetailsScreen> createState() => _ContactDetailsScreenState();
}

class _ContactDetailsScreenState extends State<ContactDetailsScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.contact?.name);
  late final _email = TextEditingController(text: widget.contact?.email);
  late final _phone = TextEditingController(text: widget.contact?.phone);
  late final _note = TextEditingController(text: widget.contact?.note);
  late bool _fav = widget.contact?.favourite ?? false;
  bool _busy = false;

  bool get _isNew => widget.contact == null;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final c = ContactModel(
      id: widget.contact?.id ?? '',
      name: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      favourite: _fav,
    );
    final repo = MiscRepository.instance;
    final r = _isNew ? await repo.createContact(c) : await repo.updateContact(c);
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.ok) {
      context.pop(true);
    } else {
      context.toast(r.error!.message, error: true);
    }
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(context, title: 'Delete contact?', message: '${widget.contact!.name} will be removed from your contacts.', confirmLabel: 'Delete', destructive: true);
    if (!ok) return;
    final r = await MiscRepository.instance.deleteContact(widget.contact!.id);
    if (!mounted) return;
    if (r.ok) {
      context.pop(true);
    } else {
      context.toast(r.error!.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'New contact' : 'Contact'),
        actions: [
          IconButton(
            icon: Icon(_fav ? Icons.star_rounded : Icons.star_outline_rounded, color: _fav ? const Color(0xFFF5B400) : null),
            tooltip: 'Favourite',
            onPressed: () => setState(() => _fav = !_fav),
          ),
          if (!_isNew) IconButton(icon: const Icon(Icons.delete_outline_rounded), tooltip: 'Delete', onPressed: _delete),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Center(child: SenderAvatar(name: _name.text, seed: _email.text, size: 84)),
          const SizedBox(height: 24),
          AppTextField(controller: _name, label: 'Name', prefixIcon: Icons.person_outline_rounded, action: TextInputAction.next, onChanged: (_) => setState(() {}), validator: (v) => Validators.required(v, 'Name')),
          const SizedBox(height: 14),
          AppTextField(controller: _email, label: 'Email', prefixIcon: Icons.mail_outline_rounded, keyboard: TextInputType.emailAddress, action: TextInputAction.next, onChanged: (_) => setState(() {}), validator: Validators.email),
          const SizedBox(height: 14),
          AppTextField(controller: _phone, label: 'Phone (optional)', prefixIcon: Icons.phone_outlined, keyboard: TextInputType.phone, action: TextInputAction.next),
          const SizedBox(height: 14),
          AppTextField(controller: _note, label: 'Note (optional)', prefixIcon: Icons.notes_rounded, maxLines: 3),
          const SizedBox(height: 24),
          PrimaryButton(label: 'Save', loading: _busy, onPressed: _save),
          if (!_isNew) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push(Routes.compose, extra: ComposeArgs(to: [EmailAddress(name: _name.text, address: _email.text)])),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Send email'),
            ),
          ],
        ]),
      ),
    );
  }
}
