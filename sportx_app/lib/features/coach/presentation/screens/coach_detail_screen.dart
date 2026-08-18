import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sportx_app/shared/models/models.dart';
import 'package:sportx_app/shared/presentation/widgets/async_state_view.dart';
import 'package:sportx_app/shared/presentation/widgets/detail_page_template.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';

class CoachDetailScreen extends ConsumerWidget {
  final String id;
  const CoachDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(coachDetailProvider(id));

    return AsyncDetailBuilder<Coach>(
      async: async,
      title: 'Coach',
      onRetry: () => ref.invalidate(coachDetailProvider(id)),
      dataBuilder: (c) => DetailPageTemplate(
        heroIcon: LucideIcons.user,
        heroImageUrl: c.profilePhotoUrl,
        title: c.fullName,
        subtitle: c.city?.name ?? '',
        rating: null,
        reviewsCount: null,
        tags: [c.sport?.name, c.specialization].whereType<String>().toList(),
        details: {
          if (c.experience != null) 'Experience': '${c.experience} years',
          if (c.sport?.name != null) 'Sport': c.sport!.name,
          if (c.specialization != null) 'Specialization': c.specialization!,
          if (c.hourlyRate != null) 'Fees': '₹${c.hourlyRate!.toStringAsFixed(0)}/session',
          if (c.contactNumber != null) 'Contact': c.contactNumber!,
        },
        addressStr: c.city?.name ?? '',
        ctaText: 'Enquire / Book',
        onCtaPressed: () => context.push('/enquire/${Uri.encodeComponent(c.fullName)}'),
        onPhonePressed: c.contactNumber == null
            ? null
            : () => launchUrl(Uri.parse('tel:${c.contactNumber}')),
        savedType: 'coach_profile',
        savedItemId: c.id.toString(),
      ),
    );
  }
}
