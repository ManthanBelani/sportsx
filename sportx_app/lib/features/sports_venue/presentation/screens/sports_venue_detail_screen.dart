import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sportx_app/shared/models/models.dart';
import 'package:sportx_app/shared/presentation/widgets/async_state_view.dart';
import 'package:sportx_app/shared/presentation/widgets/detail_page_template.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class SportsVenueDetailScreen extends ConsumerWidget {
  final String id;
  const SportsVenueDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sportsVenueDetailProvider(id));

    return AsyncDetailBuilder<SportsVenue>(
      async: async,
      title: 'Sports Venue',
      onRetry: () => ref.invalidate(sportsVenueDetailProvider(id)),
      dataBuilder: (v) => DetailPageTemplate(
        heroIcon: LucideIcons.mapPin,
        heroImageUrl: v.imageUrl,
        title: v.name,
        subtitle: v.city?.name ?? v.address ?? '',
        rating: null,
        reviewsCount: null,
        tags: [v.sport?.name].whereType<String>().toList(),
        details: {
          if (v.description != null) 'Description': v.description!,
          if (v.hourlyRate != null) 'Hourly Rate': '₹${v.hourlyRate!.toStringAsFixed(0)}/hr',
          if (v.dailyRate != null) 'Daily Rate': '₹${v.dailyRate!.toStringAsFixed(0)}/day',
          if (v.contactNumber != null) 'Contact': v.contactNumber!,
          if (v.email != null) 'Email': v.email!,
          if (v.website != null) 'Website': v.website!,
          if (v.amenities != null) 'Amenities': v.amenities!,
        },
        addressStr: v.address ?? v.city?.name ?? '',
        ctaText: v.bookingAvailable ? 'Book Now' : 'Enquire',
        onCtaPressed: () {
          if (v.bookingAvailable) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Booking feature coming soon!')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Enquiries for venues coming soon!')),
            );
          }
        },
        onPhonePressed: v.contactNumber == null
            ? null
            : () => launchUrl(Uri.parse('tel:${v.contactNumber}')),
        savedType: 'sports_venue',
        savedItemId: v.id.toString(),
      ),
    );
  }
}
