class ContactModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? note;
  final bool favourite;

  const ContactModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.note,
    this.favourite = false,
  });

  ContactModel copyWith({String? name, String? email, String? phone, String? note, bool? favourite}) =>
      ContactModel(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        note: note ?? this.note,
        favourite: favourite ?? this.favourite,
      );

  factory ContactModel.fromJson(Map<String, dynamic> j) => ContactModel(
        id: '${j['id']}',
        name: (j['name'] ?? '') as String,
        email: (j['email'] ?? '') as String,
        phone: j['phone'] as String?,
        note: j['note'] as String?,
        favourite: j['favourite'] == true || j['favourite'] == 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'note': note,
        'favourite': favourite,
      };
}
