int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

class Sport {
  final int id;
  final String name;
  final bool isActive;
  final int sortOrder;

  Sport({required this.id, required this.name, required this.isActive, required this.sortOrder});

  factory Sport.fromJson(Map<String, dynamic> json) {
    return Sport(
      id: _parseInt(json['id'])!,
      name: json['name'] as String,
      isActive: (json['is_active'] ?? 1) == 1,
      sortOrder: _parseInt(json['sort_order']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'is_active': isActive ? 1 : 0, 'sort_order': sortOrder};
}
