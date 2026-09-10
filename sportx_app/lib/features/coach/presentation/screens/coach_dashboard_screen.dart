import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/coach/presentation/providers/coach_provider.dart';
import 'package:sportx_app/features/coach/presentation/screens/coach_enquiry_inbox_screen.dart';
import 'package:sportx_app/features/coach/presentation/screens/coach_profile_edit_screen.dart';
import 'package:sportx_app/shared/models/coach.dart';
import 'package:sportx_app/core/config/api_config.dart';
import 'package:sportx_app/shared/providers/enquiry_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/date_format_utils.dart';

class CoachDashboardScreen extends ConsumerStatefulWidget {
  const CoachDashboardScreen({super.key});

  @override
  ConsumerState<CoachDashboardScreen> createState() => _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends ConsumerState<CoachDashboardScreen> {
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(coachProvider.notifier).loadCoachProfile();
      ref.read(enquiryInboxProvider.notifier).load();
    });
  }

  void _switchTab(int index) {
    if (mounted) setState(() => _currentTabIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final coachState = ref.watch(coachProvider);
    final profile = coachState.coachProfile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('SportX', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings, color: AppColors.textPrimary),
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(LucideIcons.bell, color: AppColors.textPrimary),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          _buildHomeTab(profile),
          _buildScheduleTab(),
          const CoachEnquiryInboxScreen(isTabContent: true),
          const CoachProfileEditScreen(isTabContent: true),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (index) {
          if (index == 2) {
            context.push('/coach-enquiry-inbox');
          } else if (index == 3) {
            context.push('/coach-profile-edit');
          } else {
            setState(() => _currentTabIndex = index);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(LucideIcons.home),
            selectedIcon: Icon(LucideIcons.home, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.calendar),
            selectedIcon: Icon(LucideIcons.calendar, color: AppColors.primary),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.messageCircle),
            selectedIcon: Icon(LucideIcons.messageCircle, color: AppColors.primary),
            label: 'Enquiries',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.user),
            selectedIcon: Icon(LucideIcons.user, color: AppColors.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.calendar, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Schedule Coming Soon', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      SizedBox(height: 4),
                      Text('Manage your coaching sessions and availability will be available here.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          _buildScheduleAction(LucideIcons.clock, 'Set Availability', 'Define your weekly time slots'),
          _buildScheduleAction(LucideIcons.video, 'Request Recording', 'Get trial sessions recorded'),
          _buildScheduleAction(LucideIcons.mapPin, 'Training Location', 'Indiranagar, Bangalore'),
        ],
      ),
    );
  }

  Widget _buildScheduleAction(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, color: AppColors.textSecondary, size: 20),
        ],
      ),
    );
  }

  Widget _buildHomeTab(Coach? profile) {
    final enquiryState = ref.watch(enquiryInboxProvider);
    final totalEnquiries = enquiryState.items.length;
    final newEnquiries = enquiryState.items.where((e) => e.status == 'new' && !e.isRead).length;
    final thisMonthEnquiries = totalEnquiries > 0 ? (totalEnquiries * 0.8).ceil() : 0;
    final avgRating = '4.8';
    final recentEnquiries = enquiryState.items.take(5).toList();
    final name = profile?.fullName.split(' ').first ?? 'Coach';
    
    String? photoUrl = profile?.profilePhotoUrl;
    if (photoUrl != null && photoUrl.startsWith('/')) {
      final base = ApiConfig.baseUrl.replaceAll('/api/v1', '');
      photoUrl = '$base$photoUrl';
    }
    final completeness = _calculateProfileCompleteness(profile);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null ? const Icon(LucideIcons.user, color: AppColors.primary, size: 28) : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome, $name!', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(
                        profile != null
                            ? '${profile.sport?.name ?? 'Coach'} · ${profile.city?.name ?? 'Location'}'
                            : 'Set up your profile',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      if (newEnquiries > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          'You have $newEnquiries new enquiry${newEnquiries != 1 ? 'ies' : 'y'}',
                          style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: _buildStatCard('$totalEnquiries', 'Total Enquiries')),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard('$thisMonthEnquiries', 'This Month')),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard(avgRating, 'Avg Rating', icon: LucideIcons.star)),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Profile Completeness', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Text('${(completeness * 100).toInt()}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: completeness,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 12),
                ..._buildProfileTips(profile),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quick Actions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildQuickAction(LucideIcons.user, 'Edit Profile', () => _switchTab(3)),
                    _buildQuickAction(LucideIcons.messageCircle, 'Enquiries', () => _switchTab(2)),
                    _buildQuickAction(LucideIcons.calendar, 'Schedule', () {}),
                    _buildQuickAction(LucideIcons.barChart2, 'Analytics', () {}),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent Enquiries', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    GestureDetector(
                      onTap: () => _switchTab(2),
                      child: const Text('View All', style: TextStyle(fontSize: 13, color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (recentEnquiries.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No enquiries yet', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  )
                else
                  ...recentEnquiries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final e = entry.value;
                    return Column(
                      children: [
                        if (index > 0) const Divider(color: AppColors.border),
                        _buildEnquiryItem(e.id, e.athleteName, e.message, DateFormatUtils.formatRelative(e.createdAt), e.status == 'new' && !e.isRead),
                      ],
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
              ],
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(LucideIcons.circleDot, size: 14, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 22, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildEnquiryItem(String id, String name, String preview, String time, bool isNew) {
    return GestureDetector(
      onTap: () => _switchTab(2),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary,
              child: Icon(LucideIcons.user, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(width: 6),
                      if (isNew)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFdbeafe), borderRadius: BorderRadius.circular(4)),
                          child: const Text('New', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFd1fae5), borderRadius: BorderRadius.circular(4)),
                          child: const Text('Replied', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF065f46))),
                        )
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(preview, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(time, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateProfileCompleteness(Coach? profile) {
    if (profile == null) return 0.1;
    int filled = 0;
    int total = 10;

    if (profile.fullName.isNotEmpty) filled++;
    if (profile.sport != null) filled++;
    if (profile.city != null) filled++;
    if (profile.contactNumber != null && profile.contactNumber!.isNotEmpty) filled++;
    if (profile.experience != null) filled++;
    if (profile.bio != null && profile.bio!.isNotEmpty) filled++;
    if (profile.profilePhotoUrl != null) filled++;
    if (profile.feePerSession != null || profile.feeMonthly != null) filled++;
    if (profile.headline != null && profile.headline!.isNotEmpty) filled++;
    if (profile.availability != null && profile.availability!.values.any((slots) => slots.isNotEmpty)) filled++;

    return filled / total;
  }

  List<Widget> _buildProfileTips(Coach? profile) {
    final tips = <Widget>[];
    if (profile == null) {
      tips.add(_buildTipItem('Complete your profile setup'));
      return tips;
    }

    if (profile.profilePhotoUrl == null) {
      tips.add(_buildTipItem('Add a profile photo'));
    }
    if (profile.headline == null || profile.headline!.isEmpty) {
      tips.add(_buildTipItem('Add your AIFF license certificate'));
    }
    if (profile.bio == null || profile.bio!.isEmpty) {
      tips.add(_buildTipItem('Write a bio describing your coaching approach'));
    }
    if (profile.feePerSession == null && profile.feeMonthly == null) {
      tips.add(_buildTipItem('Set your fee structure'));
    }
    if (profile.availability == null || !profile.availability!.values.any((slots) => slots.isNotEmpty)) {
      tips.add(_buildTipItem('Set your weekly availability'));
    }

    // Always add the video upload tip as it's missing in the app's capability currently
    tips.add(_buildTipItem('Upload a training video'));

    return tips;
  }
}
