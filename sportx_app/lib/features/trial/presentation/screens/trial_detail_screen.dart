import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/presentation/widgets/detail_page_template.dart';

class TrialDetailScreen extends StatelessWidget {
  final String id;
  const TrialDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return DetailPageTemplate(
      heroIcon: LucideIcons.circleDot,
      heroImageUrl: null,
      title: 'U-14 Cricket Selection Trials',
      subtitle: 'Sardar Patel Stadium, Ahmedabad',
      rating: null,
      reviewsCount: null,
      tags: const ['Cricket', 'U-14', 'Open Trial'],
      details: const {
        'Date': '15 Aug 2026',
        'Time': '8:00 AM',
        'Entry Fee': '₹200',
        'Organizer': 'Gujarat Cricket Association',
      },
      addressStr: 'Sardar Patel Stadium Compound,\nMotera, Ahmedabad, Gujarat 380009',
      ctaText: 'Register for Trial',
      onCtaPressed: () {
        context.push('/trial-registration/$id');
      },
    );
  }
}
