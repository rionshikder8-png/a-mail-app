class AttachmentModel {
  final String id;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final String? url;
  final String? localPath;

  const AttachmentModel({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    this.url,
    this.localPath,
  });

  String get extension {
    final i = fileName.lastIndexOf('.');
    return i < 0 ? '' : fileName.substring(i + 1).toLowerCase();
  }

  bool get isImage => mimeType.startsWith('image/');
  bool get isPdf => mimeType == 'application/pdf' || extension == 'pdf';

  String get sizeLabel {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory AttachmentModel.fromJson(Map<String, dynamic> j) => AttachmentModel(
        id: '${j['id']}',
        fileName: (j['file_name'] ?? 'file') as String,
        mimeType: (j['mime_type'] ?? 'application/octet-stream') as String,
        sizeBytes: (j['size_bytes'] ?? 0) as int,
        url: j['url'] as String?,
        localPath: j['local_path'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'file_name': fileName,
        'mime_type': mimeType,
        'size_bytes': sizeBytes,
        'url': url,
        'local_path': localPath,
      };
}
