import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sportx_app/core/role_config.dart';
import 'package:sportx_app/shared/models/models.dart';
import 'package:sportx_app/shared/presentation/widgets/async_state_view.dart';
import 'package:sportx_app/shared/presentation/widgets/detail_page_template.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';
import 'package:sportx_app/shared/providers/role_config_provider.dart';

class TrialDetailScreen extends ConsumerWidget {
  final String id;
  const TrialDetailScreen({super.key, required this.id});

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(trialDetailProvider(id));

    // Registration is an athlete action (the API only accepts athletes).
    // Organizers manage trials — they never register for them — so the
    // "Register for Trial" CTA is hidden for them instead of a dead button.
    final role = ref.watch(activeRoleProvider);
    final canRegister = role == null || role == SportXRole.athlete;

    return AsyncDetailBuilder<Trial>(
      async: async,
      title: 'Trial',
      onRetry: () => ref.invalidate(trialDetailProvider(id)),
      dataBuilder: (t) => DetailPageTemplate(
        heroIcon: LucideIcons.circleDot,
        heroImageUrl: null,
        title: t.title,
        subtitle: [t.venue, t.city?.name].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
        rating: null,
        reviewsCount: null,
        tags: [t.sport?.name, t.ageGroupLabel].whereType<String>().toList(),
        details: {
          if (t.trialDate != null) 'Date': _fmt(t.trialDate!),
          if (t.registrationDeadline != null) 'Deadline': _fmt(t.registrationDeadline!),
          if (t.registrationFee != null) 'Entry Fee': '₹${t.registrationFee!.toStringAsFixed(0)}',
          if (t.ageGroupLabel != null) 'Age Group': t.ageGroupLabel!,
          if (t.totalSpots != null) 'Spots': '${t.spotsLeft ?? 0} left',
          if (t.contactNumber != null) 'Contact': t.contactNumber!,
        },
        addressStr: t.venue ?? t.city?.name ?? '',
        ctaText: canRegister ? 'Register for Trial' : null,
        onCtaPressed: canRegister ? () => context.push('/trial-registration/$id') : null,
        savedType: 'trial',
        savedItemId: t.id.toString(),
        onPhonePressed: t.contactNumber == null
            ? null
            : () => launchUrl(Uri.parse('tel:${t.contactNumber!.replaceAll(' ', '')}')),
      ),
    );
  }
}
