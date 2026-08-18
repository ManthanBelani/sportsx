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

class ScholarshipDetailScreen extends ConsumerWidget {
  final String scholarshipId;
  const ScholarshipDetailScreen({super.key, required this.scholarshipId});

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(scholarshipDetailProvider(scholarshipId));

    return AsyncDetailBuilder<Scholarship>(
      async: async,
      title: 'Scholarship',
      onRetry: () => ref.invalidate(scholarshipDetailProvider(scholarshipId)),
      dataBuilder: (s) {
        final extraSections = <Widget>[
          if (s.description != null && s.description!.isNotEmpty) ...[
            _sectionHeader('About'),
            Text(s.description!, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 24),
          ],
          if (s.eligibility != null && s.eligibility!.isNotEmpty) ...[
            _sectionHeader('Eligibility'),
            Text(s.eligibility!, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 24),
          ],
          if (s.documentsRequired.isNotEmpty) ...[
            _sectionHeader('Documents Required'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: s.documentsRequired
                  .map((doc) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.fileText, size: 14, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(doc, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],
        ];

        return DetailPageTemplate(
          heroIcon: LucideIcons.graduationCap,
          heroImageUrl: null,
          title: s.title,
          subtitle: s.sponsorName ?? s.sport?.name ?? '',
          rating: null,
          reviewsCount: null,
          tags: [s.sport?.name].whereType<String>().toList(),
          details: {
            if (s.amount != null) 'Amount': '₹${s.amount!.toStringAsFixed(0)}',
            if (s.amountLabel != null && s.amount == null) 'Amount': s.amountLabel!,
            if (s.applicationDeadline != null) 'Deadline': _fmt(s.applicationDeadline!),
            if (s.sport?.name != null) 'Sport': s.sport!.name,
            if (s.totalSlots != null) 'Slots': '${(s.totalSlots ?? 0) - (s.filledSlots ?? 0)} left',
            if (s.contactEmail != null) 'Email': s.contactEmail!,
            if (s.contactPhone != null) 'Contact': s.contactPhone!,
          },
          extraSections: extraSections,
          addressStr: s.sponsorName ?? '',
          ctaText: 'Apply Now',
          onCtaPressed: () async {
            final url = Uri.parse(s.applicationLink ?? '');
            if (s.applicationLink == null || s.applicationLink!.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No application link available')),
              );
              return;
            }
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open application link')),
                );
              }
            }
          },
          onPhonePressed: s.contactPhone == null
              ? null
              : () => launchUrl(Uri.parse('tel:${s.contactPhone!.replaceAll(' ', '')}')),
          savedType: 'scholarship',
          savedItemId: s.id.toString(),
        );
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(LucideIcons.clipboardList, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
