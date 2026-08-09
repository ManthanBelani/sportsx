import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/presentation/widgets/detail_page_template.dart';

class CoachDetailScreen extends StatelessWidget {
  final String id;
  const CoachDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return DetailPageTemplate(
      heroIcon: LucideIcons.user,
      heroImageUrl: null,
      title: 'Rahul Mehta',
      subtitle: 'Ahmedabad, Gujarat',
      rating: '4.9',
      reviewsCount: '(89 reviews)',
      tags: const ['Cricket', 'Fast Bowling', 'Private Coaching'],
      details: const {
        'Qualifications': 'BCCI Level 2',
        'Experience': '8 years',
        'Sport': 'Cricket',
        'Fees': '₹800/session',
      },
      addressStr: 'Ahmedabad, Gujarat (Available for travel within city)\n+91 98XXX XXXXX',
      ctaText: 'Enquire / Book',
      onCtaPressed: () {
        context.push('/enquire/Rahul%20Mehta');
      },
    );
  }
}
