import 'sport.dart';
import 'city.dart';

class Academy {
  final int id;
  final String name;
  final String? description;
  final String? address;
  final String? googleMapsUrl;
  final String? contactNumber;
  final String? email;
  final String? website;
  final String? logoUrl;
  final String? coverImageUrl;
  final int? cityId;
  final int? sportId;
  final double? hourlyRate;
  final double? monthlyRate;
  final String? registrationLink;
  final String status;
  final City? city;
  final Sport? sport;
  final bool isSaved;

  Academy({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.googleMapsUrl,
    this.contactNumber,
    this.email,
    this.website,
    this.logoUrl,
    this.coverImageUrl,
    this.cityId,
    this.sportId,
    this.hourlyRate,
    this.monthlyRate,
    this.registrationLink,
    required this.status,
    this.city,
    this.sport,
    this.isSaved = false,
  });

  factory Academy.fromJson(Map<String, dynamic> json) {
    return Academy(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      address: json['address'] as String?,
      googleMapsUrl: json['google_maps_url'] as String?,
      contactNumber: json['contact_number'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      logoUrl: json['logo_url'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      cityId: json['city_id'] as int?,
      sportId: json['sport_id'] as int?,
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble(),
      monthlyRate: (json['monthly_rate'] as num?)?.toDouble(),
      registrationLink: json['registration_link'] as String?,
      status: json['status'] as String? ?? 'draft',
      city: json['city'] != null ? City.fromJson(json['city']) : null,
      sport: json['sport'] != null ? Sport.fromJson(json['sport']) : null,
      isSaved: json['is_saved'] == true || json['is_saved'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'description': description, 'address': address,
    'google_maps_url': googleMapsUrl, 'contact_number': contactNumber,
    'email': email, 'website': website, 'logo_url': logoUrl,
    'cover_image_url': coverImageUrl, 'city_id': cityId, 'sport_id': sportId,
    'hourly_rate': hourlyRate, 'monthly_rate': monthlyRate,
    'registration_link': registrationLink, 'status': status,
  };
}
