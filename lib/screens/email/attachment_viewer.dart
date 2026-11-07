import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/network/api_client.dart';
import '../../core/services/file_service.dart';
import '../../models/attachment_model.dart';
import 'attachment_tile.dart';

class AttachmentViewer extends StatefulWidget {
  final AttachmentModel attachment;
  const AttachmentViewer({super.key, required this.attachment});
  @override
  State<AttachmentViewer> createState() => _AttachmentViewerState();
}

class _AttachmentViewerState extends State<AttachmentViewer> {
  String? _path;
  double _progress = 0;
  bool _downloading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _path = widget.attachment.localPath;
    _checkExisting();
  }

  Future<void> _checkExisting() async {
    final dir = await FileService.instance.downloadsDir();
    final f = File('${dir.path}/${widget.attachment.fileName}');
    if (await f.exists() && mounted) setState(() => _path = f.path);
  }

  Future<void> _download() async {
    final a = widget.attachment;
    if (a.url == null) {
      setState(() => _error = 'This attachment has no download link.');
      return;
    }
    setState(() {
      _downloading = true;
      _error = null;
      _progress = 0;
    });
    final dir = await FileService.instance.downloadsDir();
    final r = await ApiClient.instance.download(a.url!, '${dir.path}/${a.fileName}',
        onProgress: (got, total) => mounted && total > 0 ? setState(() => _progress = got / total) : null);
    if (!mounted) return;
    setState(() {
      _downloading = false;
      if (r.ok) {
        _path = r.data;
      } else {
        _error = r.error!.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.attachment;
    final cs = context.colors;
    final canPreview = a.isImage && _path != null;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => context.pop()),
        title: Text(a.fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleMedium),
        actions: [
          if (_path != null)
            IconButton(
              tooltip: 'Share',
              icon: const Icon(Icons.share_outlined),
              onPressed: () => FileService.instance.share(_path!),
            ),
        ],
      ),
      body: canPreview
          ? InteractiveViewer(child: Center(child: Image.file(File(_path!))))
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(color: attachmentColor(a).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(24)),
                    child: Icon(attachmentIcon(a), size: 44, color: attachmentColor(a)),
                  ),
                  const SizedBox(height: 20),
                  Text(a.fileName, style: context.text.titleMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text('${a.sizeLabel} · ${a.mimeType}', style: context.text.bodySmall),
                  const SizedBox(height: 24),
                  if (_error != null) ...[
                    Text(_error!, style: TextStyle(color: cs.error), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                  ],
                  if (_downloading)
                    Column(children: [
                      LinearProgressIndicator(value: _progress == 0 ? null : _progress),
                      const SizedBox(height: 8),
                      Text('Downloading… ${(_progress * 100).toStringAsFixed(0)}%', style: context.text.bodySmall),
                    ])
                  else if (_path != null)
                    Column(children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF1E9E63)),
                      const SizedBox(height: 6),
                      Text('Saved to this device', style: context.text.bodyMedium),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => FileService.instance.share(_path!),
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: const Text('Open / share'),
                      ),
                    ])
                  else
                    FilledButton.icon(onPressed: _download, icon: const Icon(Icons.download_rounded), label: const Text('Download')),
                ]),
              ),
            ),
    );
  }
}
