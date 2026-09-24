import 'package:flutter/material.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sportx_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:sportx_app/features/admin/presentation/screens/admin_web_layout.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';

class UserDetailVerifyScreen extends ConsumerStatefulWidget {
  final AdminUser user;

  const UserDetailVerifyScreen({super.key, required this.user});

  @override
  ConsumerState<UserDetailVerifyScreen> createState() =>
      _UserDetailVerifyScreenState();
}

class _UserDetailVerifyScreenState extends ConsumerState<UserDetailVerifyScreen> {
  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return AdminWebLayout(
      title: 'User Verification',
      actions: [
        if (!user.isVerified)
          TextButton.icon(
            onPressed: () => _verifyUser(user.id),
            icon: const Icon(LucideIcons.circleCheck, color: AppColors.primaryDarker),
            label: Text(
              'Verify User',
              style: GoogleFonts.inter(
                  color: AppColors.primaryDarker, fontWeight: FontWeight.w700),
            ),
          ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(user),
            const SizedBox(height: 24),
            _buildVerificationDocuments(user),
            const SizedBox(height: 24),
            _buildVerificationChecklist(user),
            const SizedBox(height: 24),
            _buildActionButtons(user),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(AdminUser user) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: user.profilePhotoUrl != null
                  ? NetworkImage(user.profilePhotoUrl!)
                  : null,
              backgroundColor: AppColors.yellowTint,
              child: user.profilePhotoUrl == null
                  ? const Icon(LucideIcons.user, size: 50, color: AppColors.primaryDark)
                  : null,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user.name,
                  style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
                if (user.isVerified) ...[
                  const SizedBox(width: 8),
                  const Icon(LucideIcons.badgeCheck, color: AppColors.verifiedBadge, size: 24),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              user.role.toUpperCase(),
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(LucideIcons.mail, user.email),
            if (user.phone != null)
              _buildInfoRow(LucideIcons.phone, user.phone!),
            if (user.city != null)
              _buildInfoRow(LucideIcons.mapPin, user.city!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(text, style: GoogleFonts.inter(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildVerificationDocuments(AdminUser user) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionLabel(label: 'Verification Documents'),
            const SizedBox(height: 16),
            if (user.documents != null && user.documents!.isNotEmpty)
              ...user.documents!.map((doc) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildDocumentPreview('Document', doc),
              ))
            else
              _buildEmptyDocument('Documents'),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentPreview(String title, String url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.imageOff, size: 48, color: AppColors.textTertiary),
                    const SizedBox(height: 8),
                    Text('Failed to load image', style: GoogleFonts.inter(color: AppColors.textTertiary)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyDocument(String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.triangleAlert, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$title not uploaded',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationChecklist(AdminUser user) {
    final checks = [
      _VerificationCheck(
        title: 'Profile Photo',
        isComplete: user.profilePhotoUrl != null,
        description: user.profilePhotoUrl != null ? 'Photo uploaded' : 'No profile photo',
      ),
      _VerificationCheck(
        title: 'Documents',
        isComplete: user.documents != null && user.documents!.isNotEmpty,
        description: user.documents != null && user.documents!.isNotEmpty
            ? 'Documents uploaded'
            : 'No documents uploaded',
      ),
      _VerificationCheck(
        title: 'Verified',
        isComplete: user.isVerified,
        description: user.isVerified ? 'User verified' : 'Pending verification',
      ),
    ];

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionLabel(label: 'Verification Checklist'),
            const SizedBox(height: 16),
            ...checks.map((check) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    check.isComplete
                        ? LucideIcons.circleCheck
                        : LucideIcons.circle,
                    color: check.isComplete ? AppColors.success : AppColors.textTertiary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          check.title,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          check.description,
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(AdminUser user) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionLabel(label: 'Actions'),
            const SizedBox(height: 16),
            if (!user.isVerified)
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                    label: 'Approve Verification',
                    icon: LucideIcons.check,
                    onPressed: () => _verifyUser(user.id)),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SecondaryButton(
                  label: 'Reject Verification',
                  onPressed: () => _rejectVerification(user.id)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyUser(String userId) async {
    await ref.read(adminProvider.notifier).approveUser(userId);
    if (mounted) {
      SnackBarUtils.showSuccess(context, 'User verified successfully');
      context.pop();
    }
  }

  Future<void> _rejectVerification(String userId) async {
    await ref.read(adminProvider.notifier).rejectUser(userId);
    if (mounted) {
      SnackBarUtils.showSuccess(context, 'Verification rejected');
      context.pop();
    }
  }
}

class _VerificationCheck {
  final String title;
  final bool isComplete;
  final String description;

  const _VerificationCheck({
    required this.title,
    required this.isComplete,
    required this.description,
  });
}
