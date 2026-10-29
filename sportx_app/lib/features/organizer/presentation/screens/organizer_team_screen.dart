import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/organizer/presentation/providers/organizer_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_cards.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// OR.16 My Team / Staff — co-organizers and volunteers the organizer
/// invites to help run their events (GET/POST /me/organizer/team).
class OrganizerTeamScreen extends ConsumerWidget {
  const OrganizerTeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = ref.watch(organizerTeamProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SportXTopBar(title: 'My Team', showBack: true),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.yellow,
        foregroundColor: AppColors.ink,
        onPressed: () => _invite(context, ref),
        icon: const Icon(LucideIcons.userPlus),
        label: Text('Invite', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: team.when(
        loading: () => const GenericListSkeleton(itemCount: 3),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.circleAlert, size: 30, color: AppColors.textSecondary),
                const SizedBox(height: 10),
                Text(
                  e is Exception ? '$e' : 'Could not load your team',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                SecondaryButton(
                  label: 'Retry',
                  onPressed: () => ref.invalidate(organizerTeamProvider),
                ),
              ],
            ),
          ),
        ),
        data: (members) {
          if (members.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 180),
                Center(
                  child: Text(
                    'No team members yet — invite a co-organizer.',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              for (final m in members)
                SportXCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.organizer.withValues(alpha: 0.12),
                        child: Text(
                          m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800, color: AppColors.organizer),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.name,
                              style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${m.roleLabel} • ${m.email}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (m.isPending)
                        const StatusPill(label: 'INVITED', kind: PillKind.pending)
                      else
                        const StatusPill(label: 'ACTIVE', kind: PillKind.ok),
                      IconButton(
                        tooltip: 'Remove',
                        icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.error),
                        onPressed: () => _remove(context, ref, m),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _invite(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final email = TextEditingController();
    String role = 'co_organizer';

    final invited = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Invite member',
                    style: GoogleFonts.sora(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
                const SizedBox(height: 16),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'co_organizer', child: Text('Co-organizer')),
                    DropdownMenuItem(value: 'volunteer', child: Text('Volunteer')),
                    DropdownMenuItem(value: 'staff', child: Text('Staff')),
                    DropdownMenuItem(value: 'finance', child: Text('Finance')),
                  ],
                  onChanged: (v) => setSheetState(() => role = v ?? role),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'Send invite',
                    icon: LucideIcons.send,
                    onPressed: () async {
                      final memberName = name.text.trim();
                      final memberEmail = email.text.trim();
                      if (memberName.isEmpty || memberEmail.isEmpty) {
                        SnackBarUtils.showError(ctx, 'Name and email are required');
                        return;
                      }
                      if (!memberEmail.contains('@')) {
                        SnackBarUtils.showError(ctx, 'Enter a valid email address');
                        return;
                      }
                      final (ok, error) = await ref
                          .read(organizerTeamActionsProvider)
                          .invite(name: memberName, email: memberEmail, role: role);
                      if (!ctx.mounted) return;
                      if (ok) {
                        SnackBarUtils.showSuccess(ctx, 'Invite sent to $memberEmail');
                        Navigator.of(ctx).pop(true);
                      } else {
                        SnackBarUtils.showError(ctx, error ?? 'Could not send the invite');
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    name.dispose();
    email.dispose();
    if (invited == true) ref.invalidate(organizerTeamProvider);
  }

  Future<void> _remove(BuildContext context, WidgetRef ref, OrganizerTeamMember member) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Remove member',
      message: 'Remove ${member.name} from your team?',
      confirmText: 'Remove',
      cancelText: 'Cancel',
    );
    if (!confirmed || !context.mounted) return;

    final (ok, error) = await ref.read(organizerTeamActionsProvider).remove(member.id);
    if (!context.mounted) return;
    if (ok) {
      SnackBarUtils.showSuccess(context, '${member.name} removed');
    } else {
      SnackBarUtils.showError(context, error ?? 'Could not remove the member');
    }
  }
}
