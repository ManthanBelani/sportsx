import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_cards.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// A.8 Permissions Primer — rationale cards for location, notifications, media.
class PermissionsPrimerScreen extends StatelessWidget {
  const PermissionsPrimerScreen({super.key});

  static const _items = [
    (
      LucideIcons.mapPin,
      'Location',
      'Find academies, coaches and events near you.',
      AppColors.infoLight,
      AppColors.info,
    ),
    (
      LucideIcons.bell,
      'Notifications',
      'Get alerts for registrations, enquiries and matches.',
      AppColors.yellowTint,
      AppColors.warnText,
    ),
    (
      LucideIcons.image,
      'Photos & Media',
      'Upload profile photos, achievements and highlights.',
      AppColors.successLight,
      AppColors.academy,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SportXTopBar(title: 'Permissions', showBack: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('A few things to get started',
                  style: GoogleFonts.sora(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
              const SizedBox(height: 6),
              Text('You can change these anytime in Settings.',
                  style: GoogleFonts.inter(
                      fontSize: 13.5, color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    for (final it in _items)
                      SportXCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(15),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                  color: it.$4,
                                  borderRadius: BorderRadius.circular(14)),
                              alignment: Alignment.center,
                              child: Icon(it.$1, size: 22, color: it.$5),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(it.$2,
                                      style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.ink)),
                                  const SizedBox(height: 2),
                                  Text(it.$3,
                                      style: GoogleFonts.inter(
                                          fontSize: 12.5,
                                          color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Allow all',
                  icon: LucideIcons.check,
                  onPressed: () => _finish(context),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: SecondaryButton(
                  label: 'Skip for now',
                  onPressed: () => _finish(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _finish(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }
}
