class LabelModel {
  final String id;
  final String name;
  final int colorValue;
  final int count;

  const LabelModel({required this.id, required this.name, required this.colorValue, this.count = 0});

  LabelModel copyWith({String? name, int? colorValue, int? count}) => LabelModel(
        id: id,
        name: name ?? this.name,
        colorValue: colorValue ?? this.colorValue,
        count: count ?? this.count,
      );

  factory LabelModel.fromJson(Map<String, dynamic> j) => LabelModel(
        id: '${j['id']}',
        name: (j['name'] ?? '') as String,
        colorValue: (j['color'] ?? 0xFF1F6BFF) as int,
        count: (j['count'] ?? 0) as int,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'color': colorValue, 'count': count};
}
