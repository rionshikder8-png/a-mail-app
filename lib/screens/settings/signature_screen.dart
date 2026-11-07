import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/extensions/context_extensions.dart';
import '../../providers/settings_provider.dart';

class SignatureScreen extends StatefulWidget {
  const SignatureScreen({super.key});
  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  late final _c = TextEditingController(text: context.read<SettingsProvider>().signature);
  late bool _on = context.read<SettingsProvider>().signatureEnabled;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signature'), actions: [
        TextButton(
          onPressed: () async {
            await context.read<SettingsProvider>().setSignature(_c.text.trim(), _on);
            if (context.mounted) {
              context.toast('Signature saved');
              context.pop();
            }
          },
          child: const Text('Save'),
        ),
      ]),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Add signature to new messages'), value: _on, onChanged: (v) => setState(() => _on = v)),
        const SizedBox(height: 8),
        TextField(controller: _c, enabled: _on, minLines: 5, maxLines: 10, decoration: const InputDecoration(hintText: 'Best regards,\nYour name')),
        const SizedBox(height: 16),
        Text('Preview', style: context.text.labelSmall),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: context.colors.surfaceContainerLow, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.colors.outlineVariant)),
          child: Text(_on && _c.text.trim().isNotEmpty ? '-- \n${_c.text.trim()}' : 'No signature', style: context.text.bodyMedium),
        ),
      ]),
    );
  }
}
