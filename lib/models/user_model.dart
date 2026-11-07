class UserModel {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String? recoveryEmail;
  final String? recoveryPhone;
  final bool emailVerified;
  final bool twoFactorEnabled;
  final String plan;

  const UserModel({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.recoveryEmail,
    this.recoveryPhone,
    this.emailVerified = false,
    this.twoFactorEnabled = false,
    this.plan = 'free',
  });

  String get address => '$username@adverune.store';

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return username.isEmpty ? '?' : username[0].toUpperCase();
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  UserModel copyWith({
    String? displayName,
    String? avatarUrl,
    String? recoveryEmail,
    String? recoveryPhone,
    bool? emailVerified,
    bool? twoFactorEnabled,
    String? plan,
  }) =>
      UserModel(
        id: id,
        username: username,
        displayName: displayName ?? this.displayName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        recoveryEmail: recoveryEmail ?? this.recoveryEmail,
        recoveryPhone: recoveryPhone ?? this.recoveryPhone,
        emailVerified: emailVerified ?? this.emailVerified,
        twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
        plan: plan ?? this.plan,
      );

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: '${j['id']}',
        username: (j['username'] ?? '') as String,
        displayName: (j['display_name'] ?? j['username'] ?? '') as String,
        avatarUrl: j['avatar_url'] as String?,
        recoveryEmail: j['recovery_email'] as String?,
        recoveryPhone: j['recovery_phone'] as String?,
        emailVerified: j['email_verified'] == true || j['email_verified'] == 1,
        twoFactorEnabled: j['two_factor_enabled'] == true || j['two_factor_enabled'] == 1,
        plan: (j['plan'] ?? 'free') as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'recovery_email': recoveryEmail,
        'recovery_phone': recoveryPhone,
        'email_verified': emailVerified,
        'two_factor_enabled': twoFactorEnabled,
        'plan': plan,
      };
}
