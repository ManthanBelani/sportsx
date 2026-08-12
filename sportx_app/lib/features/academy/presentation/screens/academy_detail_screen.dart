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

class AcademyDetailScreen extends ConsumerWidget {
  final String id;
  const AcademyDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(academyDetailProvider(id));

    return AsyncDetailBuilder<Academy>(
      async: async,
      title: 'Academy',
      onRetry: () => ref.invalidate(academyDetailProvider(id)),
      dataBuilder: (a) => DetailPageTemplate(
        heroIcon: LucideIcons.building2,
        heroImageUrl: a.coverImageUrl,
        title: a.name,
        subtitle: a.city?.name ?? a.address ?? '',
        rating: null,
        reviewsCount: null,
        tags: [a.sport?.name].whereType<String>().toList(),
        details: {
          if (a.monthlyRate != null) 'Fees': '₹${a.monthlyRate!.toStringAsFixed(0)}/mo',
          if (a.hourlyRate != null) 'Hourly': '₹${a.hourlyRate!.toStringAsFixed(0)}/hr',
          if (a.sport?.name != null) 'Sport': a.sport!.name,
          if (a.contactNumber != null) 'Contact': a.contactNumber!,
          if (a.email != null) 'Email': a.email!,
          if (a.website != null) 'Website': a.website!,
        },
        addressStr: a.address ?? a.city?.name ?? '',
        ctaText: 'Enquire Now',
        onCtaPressed: () => context.push('/enquire/${Uri.encodeComponent(a.name)}'),
        onPhonePressed: a.contactNumber == null
            ? null
            : () => launchUrl(Uri.parse('tel:${a.contactNumber}')),
      ),
    );
  }
}
