import 'package:flutter/material.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/academy/presentation/providers/academy_provider.dart';
import 'package:sportx_app/shared/models/academy.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/social_links.dart';
import 'package:sportx_app/shared/models/trial.dart';
import 'package:sportx_app/theme/colors.dart';

/// Read-only academy profile view (design: profile-view.html).
/// Editing happens on /edit-academy-profile, reached via the pencil button.
class AcademyProfileScreen extends ConsumerStatefulWidget {
  const AcademyProfileScreen({super.key});

  @override
  ConsumerState<AcademyProfileScreen> createState() => _AcademyProfileScreenState();
}

class _AcademyProfileScreenState extends ConsumerState<AcademyProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (ref.read(myTrialsProvider).items.isEmpty) {
        ref.read(myTrialsProvider.notifier).load();
      }
    });
  }

  Future<void> _openEdit() async {
    await context.push('/edit-academy-profile');
    if (mounted) {
      ref.invalidate(myAcademyProvider);
      ref.read(myTrialsProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final academyAsync = ref.watch(myAcademyProvider);
    final trialsState = ref.watch(myTrialsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.canPop() ? context.pop() : context.go('/academy-dashboard'),
        ),
        title: const Text('My Profile',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.pencil, size: 20, color: AppColors.textPrimary),
            onPressed: _openEdit,
            tooltip: 'Edit profile',
          ),
        ],
      ),
      body: academyAsync.when(
        loading: () => const GenericDetailSkeleton(),
        error: (e, _) => ListView(
          padding: const EdgeInsets.all(32),
          children: [
            Text('Could not load profile: ${ApiException.messageFor(e)}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ref.invalidate(myAcademyProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
        data: (academy) => _ProfileBody(academy: academy, trials: trialsState.items),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final Academy academy;
  final List<Trial> trials;

  const _ProfileBody({required this.academy, required this.trials});

  int get _activeTrials => trials.where((t) => t.status == 'published').length;
  int get _draftTrials => trials.where((t) => t.status == 'draft').length;

  String get _meta {
    final sports = academy.sports.map((s) => s.name).toList();
    if (sports.isEmpty) return academy.city?.name ?? 'Academy';
    if (academy.city?.name == null) return sports.join(' · ');
    return '${sports.join(' · ')} · ${academy.city!.name}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 8),
          _StatsRow(total: trials.length, active: _activeTrials, drafts: _draftTrials),
          const SizedBox(height: 8),
          if (academy.description != null && academy.description!.trim().isNotEmpty) ...[
            _Section(
              icon: LucideIcons.fileText,
              title: 'About',
              child: Text(
                academy.description!,
                style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textPrimary),
              ),
            ),
          ],
          if (academy.sports.isNotEmpty)
            _Section(
              icon: LucideIcons.dumbbell,
              title: 'Sports Offered',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: academy.sports
                    .map((s) => _Tag(label: s.name))
                    .toList(),
              ),
            ),
          if (academy.facilities.isNotEmpty)
            _Section(
              icon: LucideIcons.checkCircle,
              title: 'Facilities',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: academy.facilities.map((f) => _Tag(label: f)).toList(),
              ),
            ),
          _Section(
            icon: LucideIcons.info,
            title: 'Details',
            child:             _InfoGrid(items: [
              _InfoItem('Fee Range', academy.feeRange),
              _InfoItem('Timings', academy.timings),
              if (academy.ageGroups.isNotEmpty)
                _InfoItem('Age Groups', academy.ageGroups.join(', ')),
              _InfoItem('City', academy.city?.name),
              _InfoItem('Address', academy.address),
            ]),
          ),
          _Section(
            icon: LucideIcons.phone,
            title: 'Contact',
            child: Column(
              children: [
                if (academy.contactNumber != null && academy.contactNumber!.isNotEmpty)
                  _ContactRow(icon: LucideIcons.phone, text: academy.contactNumber!),
                if (academy.email != null && academy.email!.isNotEmpty)
                  _ContactRow(icon: LucideIcons.mail, text: academy.email!),
                if (academy.website != null && academy.website!.isNotEmpty)
                  _ContactRow(icon: LucideIcons.globe, text: academy.website!),
                if ((academy.contactNumber == null || academy.contactNumber!.isEmpty) &&
                    (academy.email == null || academy.email!.isEmpty) &&
                    (academy.website == null || academy.website!.isEmpty))
                  const Text('No contact details added yet',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
          _Section(
            icon: LucideIcons.share2,
            title: 'Social Links',
            trailing: _EditLinksButton(),
            child: academy.socialLinks.isEmpty
                ? const Text('No social links yet. Tap edit to add them.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary))
                : SocialLinksRow(links: academy.socialLinks),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
              border: Border.all(color: AppColors.border, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: academy.logoUrl != null
                ? Image.network(
                    academy.logoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                        LucideIcons.building2, size: 36, color: AppColors.primary),
                  )
                : const Icon(LucideIcons.building2, size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            academy.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            _meta,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.primary),
          ),
          if (academy.address != null && academy.address!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.mapPin, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    academy.address!,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int total;
  final int active;
  final int drafts;

  const _StatsRow({required this.total, required this.active, required this.drafts});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _Stat(value: total, label: 'Trials'),
          _divider(),
          _Stat(value: active, label: 'Active'),
          _divider(),
          _Stat(value: drafts, label: 'Drafts'),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 28, color: AppColors.border);
}

class _Stat extends StatelessWidget {
  final int value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$value',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  const _Section({required this.icon, required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;

  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
    );
  }
}

class _InfoItem {
  final String label;
  final String? value;

  const _InfoItem(this.label, this.value);
}

class _InfoGrid extends StatelessWidget {
  final List<_InfoItem> items;

  const _InfoGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final visible = items.where((i) => i.value != null && i.value!.trim().isNotEmpty).toList();
    if (visible.isEmpty) {
      return const Text('No details added yet',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary));
    }
    return Column(
      children: [
        for (final item in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 96,
                  child: Text(item.label,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ),
                Expanded(
                  child: Text(item.value!,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _EditLinksButton extends StatelessWidget {
  const _EditLinksButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/social-links'),
      child: const Text('Edit', style: TextStyle(fontSize: 13, color: AppColors.primary)),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContactRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
