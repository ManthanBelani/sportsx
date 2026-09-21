import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sportx_app/shared/models/models.dart';
import 'package:sportx_app/shared/presentation/widgets/async_state_view.dart';
import 'package:sportx_app/shared/presentation/widgets/detail_page_template.dart';
import 'package:sportx_app/shared/presentation/widgets/social_links.dart';
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
        heroImageUrl: a.coverImageUrl ?? a.logoUrl,
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
        extraSections: [
          if (a.description != null && a.description!.isNotEmpty) ...[
            Row(
              children: [
                Icon(LucideIcons.alignLeft, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('About', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 12),
            Text(a.description!, style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
          ],
          if (a.socialLinks.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(LucideIcons.share2, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Social Links', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 12),
            SocialLinksRow(links: a.socialLinks),
          ],
        ],
        addressStr: a.address ?? a.city?.name ?? '',
        ctaText: 'Enquire Now',
        onCtaPressed: () => context.push('/enquire/academy/${a.id}/${Uri.encodeComponent(a.name)}'),
        onPhonePressed: a.contactNumber == null
            ? null
            : () => launchUrl(Uri.parse('tel:${a.contactNumber}')),
        savedType: 'academy',
        savedItemId: a.id.toString(),
      ),
    );
  }
}
