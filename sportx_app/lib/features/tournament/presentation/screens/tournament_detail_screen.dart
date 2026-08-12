import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/models/models.dart';
import 'package:sportx_app/shared/presentation/widgets/async_state_view.dart';
import 'package:sportx_app/shared/presentation/widgets/detail_page_template.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';

class TournamentDetailScreen extends ConsumerWidget {
  final String id;
  const TournamentDetailScreen({super.key, required this.id});

  String _dates(DateTime s, DateTime e) {
    if (s.month == e.month && s.year == e.year) {
      return '${s.day}–${e.day}/${s.month}/${s.year}';
    }
    return '${s.day}/${s.month}–${e.day}/${e.month}/${e.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tournamentDetailProvider(id));

    return AsyncDetailBuilder<Tournament>(
      async: async,
      title: 'Tournament',
      onRetry: () => ref.invalidate(tournamentDetailProvider(id)),
      dataBuilder: (t) => DetailPageTemplate(
        heroIcon: LucideIcons.trophy,
        heroImageUrl: null,
        title: t.title,
        subtitle: [t.venue, t.city?.name].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
        rating: null,
        reviewsCount: null,
        tags: [t.sport?.name, t.format, t.ageGroupLabel].whereType<String>().toList(),
        details: {
          if (t.startDate != null && t.endDate != null) 'Dates': _dates(t.startDate!, t.endDate!),
          if (t.format != null) 'Format': t.format!,
          if (t.prizePool != null) 'Prize Pool': '₹${t.prizePool!.toStringAsFixed(0)}',
          if (t.registrationFee != null) 'Entry Fee': '₹${t.registrationFee!.toStringAsFixed(0)}',
          if (t.ageGroupLabel != null) 'Age Group': t.ageGroupLabel!,
        },
        addressStr: t.venue ?? t.city?.name ?? '',
        ctaText: 'Register',
        onCtaPressed: () => context.push('/tournament-registration/$id'),
      ),
    );
  }
}
