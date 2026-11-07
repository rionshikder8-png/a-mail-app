class StorageModel {
  final int usedBytes;
  final int quotaBytes;
  final int attachmentsBytes;
  final int mailBytes;
  final int trashBytes;

  const StorageModel({
    required this.usedBytes,
    required this.quotaBytes,
    this.attachmentsBytes = 0,
    this.mailBytes = 0,
    this.trashBytes = 0,
  });

  double get fraction => quotaBytes <= 0 ? 0 : (usedBytes / quotaBytes).clamp(0.0, 1.0);

  static String format(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    if (b < 1024 * 1024 * 1024) return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(b / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  factory StorageModel.fromJson(Map<String, dynamic> j) => StorageModel(
        usedBytes: (j['used_bytes'] ?? 0) as int,
        quotaBytes: (j['quota_bytes'] ?? 0) as int,
        attachmentsBytes: (j['attachments_bytes'] ?? 0) as int,
        mailBytes: (j['mail_bytes'] ?? 0) as int,
        trashBytes: (j['trash_bytes'] ?? 0) as int,
      );
}
