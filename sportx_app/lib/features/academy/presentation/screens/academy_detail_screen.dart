import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/presentation/widgets/detail_page_template.dart';
import 'package:sportx_app/theme/colors.dart';

class AcademyDetailScreen extends StatelessWidget {
  final String id;
  const AcademyDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return DetailPageTemplate(
      heroIcon: LucideIcons.circleDot,
      heroImageUrl: null,
      title: 'Elite Cricket Academy',
      subtitle: 'Ahmedabad, Gujarat',
      rating: '4.8',
      reviewsCount: '(124 reviews)',
      tags: const ['Cricket', 'U-12, U-14, U-16', 'Evening Batch'],
      details: const {
        'Age Groups': 'U-12, U-14, U-16, Open',
        'Timings': '6–9 AM, 4–7 PM',
        'Fees': '₹2,000 – ₹5,000/mo',
        'Facilities': 'Turf, Nets, Gym',
      },
      extraSections: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.users, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('Coaches', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 12),
            _buildCoachCard(context, 'Rahul Mehta', 'BCCI Level 2 · 8 yrs experience'),
            const SizedBox(height: 8),
            _buildCoachCard(context, 'Vikram Singh', 'BCCI Level 1 · 5 yrs experience'),
          ],
        )
      ],
      locationMap: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.map, size: 24, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          const Text('Map Preview', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
      addressStr: 'Sardar Patel Stadium Compound,\nMotera, Ahmedabad, Gujarat 380009\n+91 98XXX XXXXX',
      ctaText: 'Enquire Now',
      onCtaPressed: () {
        context.push('/enquire/Elite%20Cricket%20Academy');
      },
      onPhonePressed: () {
        // Phone button pressed - implement call action
      },
    );
  }

  Widget _buildCoachCard(BuildContext context, String name, String meta) {
    return GestureDetector(
      onTap: () => context.push('/coach-profile-detail/1'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(LucideIcons.user, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  Text(meta, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
