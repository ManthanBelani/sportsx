import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/presentation/widgets/detail_page_template.dart';

class TournamentDetailScreen extends StatelessWidget {
  final String id;
  const TournamentDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return DetailPageTemplate(
      heroIcon: LucideIcons.trophy,
      heroImageUrl: null,
      title: 'State Cricket Cup 2026',
      subtitle: 'Ahmedabad, Gujarat',
      rating: null,
      reviewsCount: null,
      tags: const ['T20', 'U-16', 'State Level'],
      details: const {
        'Dates': '10-20 Sep 2026',
        'Format': 'T20 Knockout',
        'Prize Pool': '₹50,000',
        'Entry Fee': '₹1,500/team',
      },
      addressStr: 'Multiple Venues, Ahmedabad',
      ctaText: 'Register Team',
      onCtaPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration coming soon')),
        );
      },
    );
  }
}
