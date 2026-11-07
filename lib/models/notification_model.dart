class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type; // new_email | security | system
  final String? emailId;
  final DateTime createdAt;
  final bool read;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.emailId,
    this.read = false,
  });

  NotificationModel copyWith({bool? read}) => NotificationModel(
        id: id,
        title: title,
        body: body,
        type: type,
        createdAt: createdAt,
        emailId: emailId,
        read: read ?? this.read,
      );

  factory NotificationModel.fromJson(Map<String, dynamic> j) => NotificationModel(
        id: '${j['id']}',
        title: (j['title'] ?? '') as String,
        body: (j['body'] ?? '') as String,
        type: (j['type'] ?? 'system') as String,
        emailId: j['email_id']?.toString(),
        createdAt: DateTime.tryParse('${j['created_at']}') ?? DateTime.now(),
        read: j['read'] == true || j['read'] == 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type,
        'email_id': emailId,
        'created_at': createdAt.toIso8601String(),
        'read': read,
      };
}
