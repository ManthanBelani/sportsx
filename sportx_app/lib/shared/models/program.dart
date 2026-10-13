int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Training program (Phase 5): owned by a coach or academy profile.
class Program {
  final int id;
  final String title;
  final String? sportName;
  final String? duration;
  final String mode;
  final double? price;
  final String? schedule;
  final String? about;
  final String status;

  Program({
    required this.id,
    required this.title,
    this.sportName,
    this.duration,
    this.mode = 'offline',
    this.price,
    this.schedule,
    this.about,
    this.status = 'draft',
  });

  factory Program.fromJson(Map<String, dynamic> json) {
    final sport = json['sport'] as Map<String, dynamic>?;
    return Program(
      id: _parseInt(json['id'])!,
      title: json['title'] as String? ?? 'Untitled',
      sportName: sport?['name'] as String?,
      duration: json['duration'] as String?,
      mode: json['mode'] as String? ?? 'offline',
      price: _parseDouble(json['price']),
      schedule: json['schedule'] as String?,
      about: json['about'] as String?,
      status: json['status'] as String? ?? 'draft',
    );
  }

  String get priceLabel {
    if (price == null) return 'Contact for fees';
    return '₹${price!.toStringAsFixed(0)}';
  }
}

/// Academy facility row (Phase 5): replaces the free-form facilities JSON.
class Facility {
  final int id;
  final int academyId;
  final String name;
  final String type;
  final String? size;
  final List<String> amenities;

  Facility({
    required this.id,
    required this.academyId,
    required this.name,
    this.type = 'other',
    this.size,
    this.amenities = const [],
  });

  factory Facility.fromJson(Map<String, dynamic> json) {
    return Facility(
      id: _parseInt(json['id'])!,
      academyId: _parseInt(json['academy_id']) ?? 0,
      name: json['name'] as String? ?? 'Facility',
      type: json['type'] as String? ?? 'other',
      size: json['size'] as String?,
      amenities: (json['amenities'] as List? ?? const []).map((e) => e.toString()).toList(),
    );
  }
}
