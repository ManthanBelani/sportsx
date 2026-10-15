import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/theme/colors.dart';

/// Terms of Service & Privacy Policy.
///
/// Every statement below describes behaviour actually implemented in the
/// app + API: role onboarding, guardian consent for minors, privacy
/// controls, moderation/reporting, and immediate permanent account deletion
/// (Settings > Delete Account calls DELETE /me/account).
class LegalScreen extends StatelessWidget {
  final String tab; // 'terms' | 'privacy'
  const LegalScreen({super.key, this.tab = 'terms'});

  @override
  Widget build(BuildContext context) {
    final isTerms = tab != 'privacy';
    return DefaultTabController(
      length: 2,
      initialIndex: isTerms ? 0 : 1,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: Colors.white.withValues(alpha: 0.88),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.ink),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/settings'),
          ),
          title: Text(
            'Legal',
            style: GoogleFonts.sora(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          bottom: TabBar(
            labelColor: AppColors.primaryDarker,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.yellow,
            tabs: const [
              Tab(text: 'Terms of Service'),
              Tab(text: 'Privacy Policy'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _LegalBody(sections: _terms),
            _LegalBody(sections: _privacy),
          ],
        ),
      ),
    );
  }
}

class _LegalBody extends StatelessWidget {
  final List<Map<String, String>> sections;
  const _LegalBody({required this.sections});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: sections.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, i) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sections[i]['title']!,
              style: GoogleFonts.sora(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              sections[i]['body']!,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _terms = [
  {
    'title': '1. Who can use SportX',
    'body':
        'SportX is open to athletes, coaches, academies, organizers and scouts. '
        'Athletes under 18 can only use the app with a parent or guardian\'s consent, '
        'which is verified before the account becomes active.',
  },
  {
    'title': '2. Your content',
    'body':
        'You are responsible for what you post, including profiles, listings, programs, '
        'posts and messages. Content that is fake, misleading or inappropriate can be '
        'reported by other users, reviewed by our team, and removed. Accounts that '
        'repeatedly break the rules can be suspended.',
  },
  {
    'title': '3. Trials, tournaments & opportunities',
    'body':
        'Registrations and applications made in the app are requests to the organizer or '
        'provider, who reviews and approves them. Entry fees, schedules and venues are '
        'set by the organizer — always check the listing details before registering.',
  },
  {
    'title': '4. No payments in the app',
    'body':
        'SportX does not process payments. Any fees shown on listings are informational; '
        'payment happens directly with the organizer outside the app.',
  },
  {
    'title': '5. Account deletion',
    'body':
        'You can delete your account at any time from Settings > Delete Account '
        '(your password is required to confirm). Deletion is immediate and permanent: '
        'your profile, registrations and saved items are removed.',
  },
];

const _privacy = [
  {
    'title': '1. What we store',
    'body':
        'We store your account details, the profile information you enter (sports, '
        'achievements, media), your registrations, applications, enquiries, posts and '
        'messages, plus device tokens used to deliver push notifications.',
  },
  {
    'title': '2. Privacy controls',
    'body':
        'From Settings > Privacy you control who can see your profile and who can '
        'message or connect with you. Private profiles are hidden from discovery and '
        'search results.',
  },
  {
    'title': '3. Minors',
    'body':
        'Athletes under 18 need verified guardian consent. Their discovery profiles hide '
        'contact details, and contacting a minor routes through their guardian first.',
  },
  {
    'title': '4. Notifications',
    'body':
        'We send in-app and push notifications about registrations, applications, '
        'connections and messages. You can tune categories from Settings > Notifications; '
        'account-security and registration-decision messages cannot be disabled.',
  },
  {
    'title': '5. Reporting issues',
    'body':
        'Every listing, post and profile has a Report option. Reports go to a moderation '
        'queue where our team reviews them. For anything else, use Help & Support in '
        'Settings.',
  },
];
