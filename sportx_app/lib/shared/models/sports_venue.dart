import 'sport.dart';
import 'city.dart';

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

class SportsVenue {
  final int id;
  final String name;
  final String? description;
  final String? address;
  final String? googleMapsUrl;
  final String? contactNumber;
  final String? email;
  final String? website;
  final int? cityId;
  final int? sportId;
  final bool bookingAvailable;
  final double? hourlyRate;
  final double? dailyRate;
  final String? amenities;
  final String? imageUrl;
  final String status;
  final Sport? sport;
  final City? city;
  final bool isSaved;

  SportsVenue({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.googleMapsUrl,
    this.contactNumber,
    this.email,
    this.website,
    this.cityId,
    this.sportId,
    this.bookingAvailable = false,
    this.hourlyRate,
    this.dailyRate,
    this.amenities,
    this.imageUrl,
    required this.status,
    this.sport,
    this.city,
    this.isSaved = false,
  });

  factory SportsVenue.fromJson(Map<String, dynamic> json) {
    return SportsVenue(
      id: _parseInt(json['id'])!,
      name: json['name'] as String,
      description: json['description'] as String?,
      address: json['address'] as String?,
      googleMapsUrl: json['google_maps_url'] as String?,
      contactNumber: json['contact_number'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      cityId: _parseInt(json['city_id']),
      sportId: _parseInt(json['sport_id']),
      bookingAvailable: json['booking_available'] == true || json['booking_available'] == 1,
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble(),
      dailyRate: (json['daily_rate'] as num?)?.toDouble(),
      // facilities is a JSON column → arrives as a List; amenities may be a String.
      amenities: _stringOrList(json['amenities'] ?? json['facilities']),
      imageUrl: json['image_url'] as String?,
      status: (json['status'] ?? json['listing_status']) as String? ?? 'draft',
      sport: json['sport'] != null ? Sport.fromJson(json['sport']) : null,
      city: json['city'] != null ? City.fromJson(json['city']) : null,
      isSaved: json['is_saved'] == true || json['is_saved'] == 1,
    );
  }

  static String? _stringOrList(dynamic v) {
    if (v == null) return null;
    if (v is List) return v.map((e) => e.toString()).join(', ');
    return v.toString();
  }
}
