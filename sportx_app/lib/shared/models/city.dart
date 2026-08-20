int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

class City {
  final int id;
  final String name;
  final String state;
  final bool isActive;

  City({required this.id, required this.name, required this.state, required this.isActive});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: _parseInt(json['id'])!,
      name: json['name'] as String,
      state: json['state'] as String? ?? '',
      isActive: (json['is_active'] ?? 1) == 1,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'state': state, 'is_active': isActive ? 1 : 0};
}
