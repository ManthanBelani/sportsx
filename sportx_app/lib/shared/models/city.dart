class City {
  final int id;
  final String name;
  final String state;
  final bool isActive;

  City({required this.id, required this.name, required this.state, required this.isActive});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] as int,
      name: json['name'] as String,
      state: json['state'] as String? ?? '',
      isActive: (json['is_active'] ?? 1) == 1,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'state': state, 'is_active': isActive ? 1 : 0};
}
