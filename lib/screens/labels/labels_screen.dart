import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/theme/colors.dart';
import '../../data/repositories/misc_repository.dart';
import '../../models/label_model.dart';
import '../../navigation/route_names.dart';
import '../../providers/email_provider.dart';
import '../../shared/dialogs/dialogs.dart';
import '../../shared/widgets/state_views.dart';

class LabelsScreen extends StatefulWidget {
  const LabelsScreen({super.key});
  @override
  State<LabelsScreen> createState() => _LabelsScreenState();
}

class _LabelsScreenState extends State<LabelsScreen> {
  List<LabelModel> _labels = [];
  LoadState _state = LoadState.loading;
  String? _error;
  final _repo = MiscRepository.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = LoadState.loading);
    final r = await _repo.labels();
    if (!mounted) return;
    setState(() {
      if (r.ok) {
        _labels = r.data ?? [];
        _state = _labels.isEmpty ? LoadState.empty : LoadState.loaded;
      } else {
        _error = r.error!.message;
        _state = LoadState.error;
      }
    });
  }

  Future<void> _edit([LabelModel? existing]) async {
    final result = await showModalBottomSheet<({String name, int color})>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _LabelEditor(initial: existing),
    );
    if (result == null) return;
    final r = existing == null ? await _repo.createLabel(result.name, result.color) : await _repo.updateLabel(existing.id, result.name, result.color);
    if (!mounted) return;
    if (r.ok) {
      context.toast(existing == null ? 'Label created' : 'Label updated');
      _load();
    } else {
      context.toast(r.error!.message, error: true);
    }
  }

  Future<void> _delete(LabelModel l) async {
    final ok = await confirmDialog(context,
        title: 'Delete "${l.name}"?', message: 'The label is removed from all messages. The messages themselves are not deleted.', confirmLabel: 'Delete', destructive: true);
    if (!ok) return;
    final r = await _repo.deleteLabel(l.id);
    if (!mounted) return;
    if (r.ok) {
      setState(() => _labels.remove(l));
      if (_labels.isEmpty) _state = LoadState.empty;
      context.toast('Label deleted');
    } else {
      context.toast(r.error!.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Labels')),
      floatingActionButton: FloatingActionButton.extended(onPressed: _edit, icon: const Icon(Icons.add_rounded), label: const Text('New label')),
      body: switch (_state) {
        LoadState.loading || LoadState.idle => const ListSkeleton(count: 5),
        LoadState.error => StateView(icon: Icons.cloud_off_rounded, title: 'Couldn\'t load labels', message: _error ?? '', actionLabel: 'Retry', onAction: _load),
        LoadState.empty => StateView.empty(icon: Icons.label_outline_rounded, title: 'No labels yet', message: 'Labels help you organise mail. Create one to get started.'),
        LoadState.loaded => ListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: _labels.length,
            itemBuilder: (_, i) {
              final l = _labels[i];
              return ListTile(
                leading: Icon(Icons.label_rounded, color: Color(l.colorValue)),
                title: Text(l.name),
                subtitle: l.count > 0 ? Text('${l.count} conversations') : null,
                onTap: () => context.push(Routes.labelPath(l.id), extra: l.name),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) => v == 'edit' ? _edit(l) : _delete(l),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Rename / recolour')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              );
            },
          ),
      },
    );
  }
}

class _LabelEditor extends StatefulWidget {
  final LabelModel? initial;
  const _LabelEditor({this.initial});
  @override
  State<_LabelEditor> createState() => _LabelEditorState();
}

class _LabelEditorState extends State<_LabelEditor> {
  late final _name = TextEditingController(text: widget.initial?.name);
  late int _color = widget.initial?.colorValue ?? AColors.labelPalette.first.toARGB32();
  String? _err;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.initial == null ? 'New label' : 'Edit label', style: context.text.titleLarge),
        const SizedBox(height: 16),
        TextField(controller: _name, autofocus: true, maxLength: 40, decoration: InputDecoration(labelText: 'Label name', errorText: _err)),
        const SizedBox(height: 8),
        Wrap(spacing: 12, runSpacing: 12, children: [
          for (final c in AColors.labelPalette)
            GestureDetector(
              onTap: () => setState(() => _color = c.toARGB32()),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                child: _color == c.toARGB32() ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : null,
              ),
            ),
        ]),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () {
            final n = _name.text.trim();
            if (n.isEmpty) return setState(() => _err = 'Enter a name');
            Navigator.pop(context, (name: n, color: _color));
          },
          child: const Text('Save'),
        ),
      ]),
    );
  }
}
