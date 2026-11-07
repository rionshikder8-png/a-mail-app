import 'attachment_model.dart';

class EmailAddress {
  final String name;
  final String address;
  const EmailAddress({required this.address, this.name = ''});

  String get display => name.isNotEmpty ? name : address;

  factory EmailAddress.fromJson(Map<String, dynamic> j) =>
      EmailAddress(name: (j['name'] ?? '') as String, address: (j['address'] ?? '') as String);

  Map<String, dynamic> toJson() => {'name': name, 'address': address};

  @override
  bool operator ==(Object other) => other is EmailAddress && other.address.toLowerCase() == address.toLowerCase();
  @override
  int get hashCode => address.toLowerCase().hashCode;
}

class EmailModel {
  final String id;
  final String threadId;
  final EmailAddress from;
  final List<EmailAddress> to;
  final List<EmailAddress> cc;
  final List<EmailAddress> bcc;
  final String subject;
  final String snippet;
  final String bodyHtml;
  final String bodyText;
  final DateTime date;
  final bool isRead;
  final bool isStarred;
  final bool isImportant;
  final String folder;
  final List<String> labelIds;
  final List<AttachmentModel> attachments;
  final int threadCount;
  final DateTime? snoozedUntil;
  final DateTime? scheduledAt;
  final bool isDraft;

  const EmailModel({
    required this.id,
    required this.threadId,
    required this.from,
    required this.subject,
    required this.date,
    this.to = const [],
    this.cc = const [],
    this.bcc = const [],
    this.snippet = '',
    this.bodyHtml = '',
    this.bodyText = '',
    this.isRead = false,
    this.isStarred = false,
    this.isImportant = false,
    this.folder = 'inbox',
    this.labelIds = const [],
    this.attachments = const [],
    this.threadCount = 1,
    this.snoozedUntil,
    this.scheduledAt,
    this.isDraft = false,
  });

  bool get hasAttachments => attachments.isNotEmpty;

  EmailModel copyWith({
    bool? isRead,
    bool? isStarred,
    bool? isImportant,
    String? folder,
    List<String>? labelIds,
    DateTime? snoozedUntil,
    bool clearSnooze = false,
  }) =>
      EmailModel(
        id: id,
        threadId: threadId,
        from: from,
        to: to,
        cc: cc,
        bcc: bcc,
        subject: subject,
        snippet: snippet,
        bodyHtml: bodyHtml,
        bodyText: bodyText,
        date: date,
        isRead: isRead ?? this.isRead,
        isStarred: isStarred ?? this.isStarred,
        isImportant: isImportant ?? this.isImportant,
        folder: folder ?? this.folder,
        labelIds: labelIds ?? this.labelIds,
        attachments: attachments,
        threadCount: threadCount,
        snoozedUntil: clearSnooze ? null : (snoozedUntil ?? this.snoozedUntil),
        scheduledAt: scheduledAt,
        isDraft: isDraft,
      );

  static List<EmailAddress> _addrs(dynamic v) =>
      (v as List? ?? const []).map((e) => EmailAddress.fromJson(Map<String, dynamic>.from(e as Map))).toList();

  factory EmailModel.fromJson(Map<String, dynamic> j) => EmailModel(
        id: '${j['id']}',
        threadId: '${j['thread_id'] ?? j['id']}',
        from: EmailAddress.fromJson(Map<String, dynamic>.from(j['from'] as Map)),
        to: _addrs(j['to']),
        cc: _addrs(j['cc']),
        bcc: _addrs(j['bcc']),
        subject: (j['subject'] ?? '') as String,
        snippet: (j['snippet'] ?? '') as String,
        bodyHtml: (j['body_html'] ?? '') as String,
        bodyText: (j['body_text'] ?? '') as String,
        date: DateTime.tryParse('${j['date']}') ?? DateTime.now(),
        isRead: j['is_read'] == true || j['is_read'] == 1,
        isStarred: j['is_starred'] == true || j['is_starred'] == 1,
        isImportant: j['is_important'] == true || j['is_important'] == 1,
        folder: (j['folder'] ?? 'inbox') as String,
        labelIds: (j['label_ids'] as List? ?? const []).map((e) => '$e').toList(),
        attachments: (j['attachments'] as List? ?? const [])
            .map((e) => AttachmentModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        threadCount: (j['thread_count'] ?? 1) as int,
        snoozedUntil: j['snoozed_until'] == null ? null : DateTime.tryParse('${j['snoozed_until']}'),
        scheduledAt: j['scheduled_at'] == null ? null : DateTime.tryParse('${j['scheduled_at']}'),
        isDraft: j['is_draft'] == true || j['is_draft'] == 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'thread_id': threadId,
        'from': from.toJson(),
        'to': to.map((e) => e.toJson()).toList(),
        'cc': cc.map((e) => e.toJson()).toList(),
        'bcc': bcc.map((e) => e.toJson()).toList(),
        'subject': subject,
        'snippet': snippet,
        'body_html': bodyHtml,
        'body_text': bodyText,
        'date': date.toIso8601String(),
        'is_read': isRead,
        'is_starred': isStarred,
        'is_important': isImportant,
        'folder': folder,
        'label_ids': labelIds,
        'attachments': attachments.map((e) => e.toJson()).toList(),
        'thread_count': threadCount,
        'snoozed_until': snoozedUntil?.toIso8601String(),
        'scheduled_at': scheduledAt?.toIso8601String(),
        'is_draft': isDraft,
      };
}
