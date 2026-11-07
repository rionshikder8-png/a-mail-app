import 'package:flutter/material.dart';
import '../../models/attachment_model.dart';

IconData attachmentIcon(AttachmentModel a) {
  if (a.isImage) return Icons.image_outlined;
  if (a.isPdf) return Icons.picture_as_pdf_outlined;
  switch (a.extension) {
    case 'doc':
    case 'docx':
    case 'txt':
      return Icons.description_outlined;
    case 'xls':
    case 'xlsx':
    case 'csv':
      return Icons.table_chart_outlined;
    case 'zip':
    case 'rar':
    case '7z':
      return Icons.folder_zip_outlined;
    case 'mp3':
    case 'wav':
      return Icons.audiotrack_outlined;
    case 'mp4':
    case 'mov':
      return Icons.videocam_outlined;
    default:
      return Icons.insert_drive_file_outlined;
  }
}

Color attachmentColor(AttachmentModel a) {
  if (a.isPdf) return const Color(0xFFD93A32);
  if (a.isImage) return const Color(0xFF7C3AED);
  switch (a.extension) {
    case 'doc':
    case 'docx':
      return const Color(0xFF1F6BFF);
    case 'xls':
    case 'xlsx':
      return const Color(0xFF1E9E63);
    default:
      return const Color(0xFF5E6985);
  }
}

class AttachmentTile extends StatelessWidget {
  final AttachmentModel attachment;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  const AttachmentTile({super.key, required this.attachment, this.onTap, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = attachmentColor(attachment);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(attachmentIcon(attachment), color: c, size: 22),
        ),
        title: Text(attachment.fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
        subtitle: Text(attachment.sizeLabel, style: Theme.of(context).textTheme.bodySmall),
        trailing: onRemove != null
            ? IconButton(icon: const Icon(Icons.close_rounded), onPressed: onRemove, tooltip: 'Remove')
            : const Icon(Icons.download_outlined, size: 20),
      ),
    );
  }
}
