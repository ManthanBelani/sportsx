import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/core/role_config.dart';
import 'package:sportx_app/shared/models/models.dart';
import 'package:sportx_app/shared/presentation/widgets/async_state_view.dart';
import 'package:sportx_app/shared/presentation/widgets/detail_page_template.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';
import 'package:sportx_app/shared/providers/role_config_provider.dart';
import 'package:sportx_app/features/trial/presentation/providers/unified_events_provider.dart';
import 'package:sportx_app/features/tournament/presentation/providers/external_registration_provider.dart';

class TournamentDetailScreen extends ConsumerWidget {
  final String id;
  const TournamentDetailScreen({super.key, required this.id});

  String _dates(DateTime s, DateTime e) {
    if (s.month == e.month && s.year == e.year) {
      return '${s.day}–${e.day}/${s.month}/${s.year}';
    }
    return '${s.day}/${s.month}–${e.day}/${e.month}/${e.year}';
  }

  /// Opens the organizer's own registration page and records the click.
  ///
  /// The click is only counted once the browser actually opened, so the
  /// counter reflects real intent and not a failed launch.
  Future<void> _openExternalRegistration(
    BuildContext context,
    WidgetRef ref,
    Tournament tournament,
  ) async {
    final raw = tournament.externalRegistrationUrl;
    if (raw == null || raw.isEmpty) {
      SnackBarUtils.showError(context, 'No registration link available for this tournament.');
      return;
    }

    final uri = Uri.tryParse(raw);
    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        !['http', 'https'].contains(uri.scheme.toLowerCase())) {
      SnackBarUtils.showError(context, 'This registration link is not valid. Please contact the organizer.');
      return;
    }

    bool opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }

    if (!opened) {
      if (context.mounted) {
        SnackBarUtils.showError(context, 'Could not open the registration page.');
      }
      return;
    }

    // Best-effort counting — never blocks the user.
    unawaited(
      ref.read(externalRegistrationRecorderProvider).record(tournament.id.toString()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tournamentDetailProvider(id));
    final results = ref.watch(eventResultsProvider(id));

    // Registration is an athlete action (the API only accepts athletes).
    // Organizers manage events — they never register for them — so the
    // "Register" CTA is hidden for them instead of showing a dead button.
    final role = ref.watch(activeRoleProvider);
    final canRegister =
        role == null || role == SportXRole.athlete;

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
          if (t.hasExternalRegistration && canRegister) 'Registration': 'On the organizer’s website',
        },
        addressStr: t.venue ?? t.city?.name ?? '',
        ctaText: canRegister ? (t.hasExternalRegistration ? 'Register externally' : 'Register') : null,
        onCtaPressed: !canRegister
            ? null
            : () => t.hasExternalRegistration
                ? _openExternalRegistration(context, ref, t)
                : context.push('/tournament-registration/$id'),
        extraSections: [
          results.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (rows) {
              final published = rows.where((r) => r['published_at'] != null).toList();
              if (published.isEmpty) return const SizedBox.shrink();
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Results', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 8),
                    ...published.map((r) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                              '#${r['place']} ${(r['winner_name'] ?? '').toString()}${r['category'] is Map ? ' • ${(r['category'] as Map)['name']}' : ''}'),
                        )),
                  ]),
                ),
              );
            },
          ),
        ],
        savedType: 'tournament',
        savedItemId: t.id.toString(),
        onPhonePressed: t.contactNumber == null
            ? null
            : () => launchUrl(Uri.parse('tel:${t.contactNumber!.replaceAll(' ', '')}')),
      ),
    );
  }
}
