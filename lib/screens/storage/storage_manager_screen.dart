import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/services/file_service.dart';
import '../../data/repositories/misc_repository.dart';
import '../../models/attachment_model.dart';
import '../../models/storage_model.dart';
import '../../providers/email_provider.dart';
import '../../shared/dialogs/dialogs.dart';
import '../email/attachment_tile.dart';
import 'package:go_router/go_router.dart';
import '../../navigation/route_names.dart';

/// Server storage usage + attachments + files downloaded on this device.
class StorageManagerScreen extends StatefulWidget {
  const StorageManagerScreen({super.key});
  @override
  State<StorageManagerScreen> createState() => _StorageManagerScreenState();
}

class _StorageManagerScreenState extends State<StorageManagerScreen> {
  StorageModel? _usage;
  List<AttachmentModel> _remoteAtt = [];
  List<File> _downloads = [];
  int _downloadsBytes = 0;
  LoadState _state = LoadState.loading;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = LoadState.loading);
    final files = (await FileService.instance.downloadedFiles()).cast<File>();
    final size = await FileService.instance.downloadsSize();
    final u = await MiscRepository.instance.storage();
    final a = u.ok ? await MiscRepository.instance.storageAttachments() : null;
    if (!mounted) return;
    setState(() {
      _downloads = files;
      _downloadsBytes = size;
      if (u.ok) {
        _usage = u.data;
        _remoteAtt = a?.data ?? [];
        _state = LoadState.loaded;
      } else {
        _error = u.error!.message;
        _state = LoadState.error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Storage')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (_state == LoadState.loading)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
          else if (_usage != null)
            _UsageCard(usage: _usage!)
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(16), border: Border.all(color: cs.outlineVariant)),
              child: Column(children: [
                Icon(Icons.cloud_off_rounded, color: cs.onSurfaceVariant, size: 32),
                const SizedBox(height: 10),
                Text('Mailbox usage unavailable', style: context.text.titleSmall),
                const SizedBox(height: 4),
                Text(_error ?? '', style: context.text.bodySmall, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                TextButton(onPressed: _load, child: const Text('Retry')),
              ]),
            ),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: Text('Downloaded on this device', style: context.text.titleMedium)),
            Text(StorageModel.format(_downloadsBytes), style: context.text.bodyMedium),
          ]),
          const SizedBox(height: 8),
          if (_downloads.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text('No downloaded attachments.', style: context.text.bodySmall))
          else ...[
            for (final f in _downloads)
              Dismissible(
                key: ValueKey(f.path),
                direction: DismissDirection.endToStart,
                background: Container(color: cs.error, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete_outline_rounded, color: Colors.white)),
                onDismissed: (_) async {
                  await FileService.instance.deleteFile(f.path);
                  _load();
                },
                child: ListTile(
                  leading: const Icon(Icons.insert_drive_file_outlined),
                  title: Text(f.path.split('/').last, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(StorageModel.format(f.lengthSync())),
                  trailing: IconButton(icon: const Icon(Icons.share_outlined), onPressed: () => FileService.instance.share(f.path)),
                ),
              ),
            TextButton.icon(
              onPressed: () async {
                if (await confirmDialog(context, title: 'Clear downloads?', message: 'Files saved on this device will be deleted. They remain in your mailbox.', confirmLabel: 'Clear', destructive: true)) {
                  await FileService.instance.clearDownloads();
                  _load();
                }
              },
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('Clear all downloads'),
            ),
          ],
          const SizedBox(height: 24),
          Text('Largest attachments in your mailbox', style: context.text.titleMedium),
          const SizedBox(height: 8),
          if (_remoteAtt.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(_usage == null ? 'Available once connected to A-Mail.' : 'No attachments.', style: context.text.bodySmall))
          else
            for (final a in _remoteAtt) AttachmentTile(attachment: a, onTap: () => context.push(Routes.attachment, extra: a)),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => context.push(Routes.plans),
            icon: const Icon(Icons.workspace_premium_outlined),
            label: const Text('Get more storage'),
          ),
        ]),
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  final StorageModel usage;
  const _UsageCard({required this.usage});

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final near = usage.fraction > 0.9;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(16), border: Border.all(color: cs.outlineVariant)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${StorageModel.format(usage.usedBytes)} of ${StorageModel.format(usage.quotaBytes)} used', style: context.text.titleMedium),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: usage.fraction, minHeight: 10, color: near ? cs.error : cs.primary, backgroundColor: cs.surfaceContainerHigh),
        ),
        const SizedBox(height: 16),
        _row(context, 'Mail', usage.mailBytes, cs.primary),
        _row(context, 'Attachments', usage.attachmentsBytes, cs.secondary),
        _row(context, 'Trash', usage.trashBytes, cs.tertiary),
        if (near) ...[
          const SizedBox(height: 8),
          Text('You\'re almost out of space. Free some up or upgrade your plan.', style: context.text.bodySmall?.copyWith(color: cs.error)),
        ],
      ]),
    );
  }

  Widget _row(BuildContext c, String l, int b, Color col) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(l, style: c.text.bodyMedium)),
          Text(StorageModel.format(b), style: c.text.bodyMedium),
        ]),
      );
}
