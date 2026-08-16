class AgeGroup {
  final int id;
  final String label;
  final int minAge;
  final int maxAge;
  final bool isActive;

  AgeGroup({required this.id, required this.label, required this.minAge, required this.maxAge, required this.isActive});

  factory AgeGroup.fromJson(Map<String, dynamic> json) {
    return AgeGroup(
      id: json['id'] as int,
      label: (json['name'] ?? json['label']) as String,
      minAge: json['min_age'] as int? ?? 0,
      maxAge: json['max_age'] as int? ?? 99,
      isActive: (json['is_active'] ?? 1) == 1,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'min_age': minAge, 'max_age': maxAge, 'is_active': isActive ? 1 : 0};
}
