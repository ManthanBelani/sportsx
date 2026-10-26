import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_cards.dart';
import 'package:sportx_app/theme/colors.dart';

/// AT.7 View as Public (P1) — read-only preview of how visitors see the profile.
class ViewAsPublicScreen extends ConsumerStatefulWidget {
  const ViewAsPublicScreen({super.key});

  @override
  ConsumerState<ViewAsPublicScreen> createState() => _ViewAsPublicScreenState();
}

class _ViewAsPublicScreenState extends ConsumerState<ViewAsPublicScreen> {
  int _tab = 0;
  static const _tabs = ['Overview', 'Posts', 'Achievements', 'Media'];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final name = user?.name ?? 'Athlete';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'A';
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          Material(
            color: AppColors.ink,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 16, 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(LucideIcons.arrowLeft,
                          color: Colors.white, size: 20),
                    ),
                    Expanded(
                      child: Text('Viewing as public',
                          style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('Preview',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ProfileHeader(
                  name: name,
                  subtitle: (user?.email ?? 'Athlete') +
                      (user?.isVerified == true ? ' · Verified' : ''),
                  avatarText: initial,
                  isVerified: user?.isVerified ?? false,
                  stats: const [
                    (value: '12', label: 'Posts'),
                    (value: '48', label: 'Connections'),
                    (value: '2', label: 'Sports'),
                    (value: '5', label: 'Achievements'),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: SegmentTabs(
                    tabs: _tabs,
                    selectedIndex: _tab,
                    onSelect: (i) => setState(() => _tab = i),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _body(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    switch (_tab) {
      case 0:
        return SportXCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('About',
                  style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
              const SizedBox(height: 6),
              Text(
                'Passionate athlete focused on cricket and football. '
                'Looking for competitive opportunities to grow.',
                style: GoogleFonts.inter(
                    fontSize: 13.5, height: 1.5, color: AppColors.dark),
              ),
            ],
          ),
        );
      case 1:
        return const EmptyState(
          icon: LucideIcons.penLine,
          title: 'No posts yet',
          message: 'Posts you publish will appear here.',
        );
      case 2:
        return const EmptyState(
          icon: LucideIcons.award,
          title: 'No achievements yet',
          message: 'Achievements you add will appear here.',
        );
      default:
        return const EmptyState(
          icon: LucideIcons.image,
          title: 'No media yet',
          message: 'Photos you upload will appear here.', // videos no longer uploadable
        );
    }
  }
}
