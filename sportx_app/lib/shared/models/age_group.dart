int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

class AgeGroup {
  final int id;
  final String label;
  final int minAge;
  final int maxAge;
  final bool isActive;

  AgeGroup({required this.id, required this.label, required this.minAge, required this.maxAge, required this.isActive});

  factory AgeGroup.fromJson(Map<String, dynamic> json) {
    return AgeGroup(
      id: _parseInt(json['id'])!,
      label: (json['name'] ?? json['label']) as String,
      minAge: _parseInt(json['min_age']) ?? 0,
      maxAge: _parseInt(json['max_age']) ?? 99,
      isActive: (json['is_active'] ?? 1) == 1,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'min_age': minAge, 'max_age': maxAge, 'is_active': isActive ? 1 : 0};
}
