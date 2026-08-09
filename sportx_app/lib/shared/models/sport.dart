class Sport {
  final int id;
  final String name;
  final bool isActive;
  final int sortOrder;

  Sport({required this.id, required this.name, required this.isActive, required this.sortOrder});

  factory Sport.fromJson(Map<String, dynamic> json) {
    return Sport(
      id: json['id'] as int,
      name: json['name'] as String,
      isActive: (json['is_active'] ?? 1) == 1,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'is_active': isActive ? 1 : 0, 'sort_order': sortOrder};
}
