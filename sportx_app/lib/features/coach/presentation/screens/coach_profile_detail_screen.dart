import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/features/coach/presentation/widgets/coach_enrollment_section.dart';
import 'package:sportx_app/features/saved/presentation/providers/saved_provider.dart';
import 'package:sportx_app/shared/models/coach.dart';
import 'package:sportx_app/shared/presentation/widgets/social_links.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';

class CoachProfileDetailScreen extends ConsumerStatefulWidget {
  final String coachId;

  const CoachProfileDetailScreen({super.key, required this.coachId});

  @override
  ConsumerState<CoachProfileDetailScreen> createState() => _CoachProfileDetailScreenState();
}

class _CoachProfileDetailScreenState extends ConsumerState<CoachProfileDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _coachData;
  String _connectionStatus = 'none';
  bool _isConnecting = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _loadCoachData();
  }

  Future<void> _loadCoachData() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/coaches/${widget.coachId}');
      if (mounted) {
        final data = response.data['data'];
        final savedState = ref.read(savedProvider);
        setState(() {
          _coachData = data;
          _isSaved = savedState.isSaved('coach_profile', widget.coachId);
          _isLoading = false;
        });
        _loadConnectionStatus();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _coachData = null;
        SnackBarUtils.showError(context, ApiException.fromDio(e is DioException ? e : DioException(requestOptions: RequestOptions(path: ''), error: e)));
      }
    }
  }

  Future<void> _handleConnect() async {
    if (_connectionStatus == 'pending' || _connectionStatus == 'accepted') return;

    final userId = _coachData?['user_id'];
    if (userId == null) return;

    setState(() => _isConnecting = true);

    try {
      final dio = ref.read(dioProvider);
      await dio.post('/me/connections/request', data: {'user_id': userId});
      if (mounted) {
        setState(() => _connectionStatus = 'pending');
        SnackBarUtils.showSuccess(context, 'Connection request sent!');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Failed to send connection request');
      }
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  Future<void> _loadConnectionStatus() async {
    final userId = _coachData?['user_id'];
    if (userId == null) return;

    try {
      final resp = await ref.read(dioProvider).get('/me/connections/status/$userId');
      if (mounted) {
        setState(() {
          _connectionStatus = resp.data['data']['status'] ?? 'none';
        });
      }
    } catch (e) {
      // Stay with 'none' status
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const CoachProfileViewSkeleton()
          : _coachData == null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(LucideIcons.triangleAlert, size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    const Text('Coach not found or unavailable'),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _loadCoachData, child: const Text('Retry')),
                    TextButton(onPressed: () => context.pop(), child: const Text('Go back')),
                  ]),
                )
              : CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(),
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildProfileInfo(),
                          const SizedBox(height: 24),
                          _buildStatsRow(),
                          const SizedBox(height: 24),
                          _buildAboutSection(),
                          const SizedBox(height: 24),
                          _buildCredentialsSection(),
                          const SizedBox(height: 24),
                          _buildFacilitiesSection(),
                          const SizedBox(height: 24),
                          _buildShowcaseAthletesSection(),
                          const SizedBox(height: 24),
                          if (_coachData != null)
                            CoachEnrollmentSection(coach: Coach.fromJson(_coachData!)),
                          const SizedBox(height: 24),
                          _buildContactSection(),
                          const SizedBox(height: 24),
                          SocialLinksSection(profile: _coachData),
                          _buildShareProfileButton(),
                          const SizedBox(height: 100),
                        ]),
                      ),
                    ),
                  ],
                ),
      bottomSheet: _coachData != null ? _buildBottomCTA() : null,
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.ink, AppColors.coach],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                    CircleAvatar(
                    radius: 40,
                    backgroundImage: _coachData!['profile_photo_url'] != null
                        ? NetworkImage(MediaUtils.resolveUrl(_coachData!['profile_photo_url']))
                        : null,
                    backgroundColor: Colors.white,
                    child: _coachData!['profile_photo_url'] == null
                        ? const Icon(LucideIcons.user, size: 40, color: AppColors.textTertiary)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              _coachData!['full_name'] ?? 'Coach',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_coachData!['is_verified'] == true) ...[
                              const SizedBox(width: 6),
                              const Icon(LucideIcons.badgeCheck, color: AppColors.yellow, size: 20),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_coachData!['specialization'] ?? "Cricket"} · ${_coachData!['city']?['name'] ?? "India"}',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(LucideIcons.heart, color: _isSaved ? AppColors.error : Colors.white),
          onPressed: () async {
            final saved = await ref.read(savedProvider.notifier).toggle(type: 'coach_profile', itemId: widget.coachId);
            if (mounted) {
              setState(() => _isSaved = saved);
              SnackBarUtils.showSuccess(context, saved ? 'Saved to your list' : 'Removed from saved');
            }
          },
        ),
        IconButton(
          icon: const Icon(LucideIcons.ellipsisVertical, color: Colors.white),
          onPressed: () => _showMoreMenu(context),
        ),
      ],
    );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.share2),
              title: const Text('Share Profile'),
              onTap: () {
                Navigator.pop(context);
                Share.share(
                  'Check out this coach on SportX India!\nhttps://sportx.in/coach/${widget.coachId}',
                );
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.link),
              title: const Text('Copy Link'),
              onTap: () {
                Navigator.pop(context);
                SnackBarUtils.showSuccess(context, 'Link copied to clipboard');
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.flag, color: Colors.red),
              title: const Text('Report', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await ref.read(dioProvider).post('/reports', data: {
                    'reportable_type': 'coach_profile',
                    'reportable_id': int.tryParse(widget.coachId) ?? widget.coachId,
                    'reason': 'spam',
                    'description': 'Reported from coach profile',
                  });
                  if (context.mounted) SnackBarUtils.showSuccess(context, 'Report submitted');
                } catch (e) {
                  if (context.mounted) SnackBarUtils.showError(context, e, 'Failed to perform action. Please try again.');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.briefcase, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              '${_coachData!['experience'] ?? 0} years experience',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(width: 16),
            Icon(LucideIcons.wallet, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              '₹${_coachData!['hourly_rate'] ?? 0}/hour',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border), boxShadow: SportXShadows.e1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('12', 'Credentials', LucideIcons.badgeCheck),
          Container(width: 1, height: 32, color: AppColors.border),
          _buildStatItem('5', 'Facilities', LucideIcons.building2),
          Container(width: 1, height: 32, color: AppColors.border),
          _buildStatItem('8', 'Athletes', LucideIcons.users),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Text(
          _coachData!['bio'] ?? 'No bio available.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildCredentialsSection() {
    final credentials = _coachData!['credentials'] as List? ?? [];
    if (credentials.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Credentials', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...credentials.map((credential) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border), boxShadow: SportXShadows.e1),
              child: Row(
                children: [
                  const Icon(LucideIcons.badgeCheck, color: AppColors.success, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          credential['title'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          credential['year'] ?? '',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFacilitiesSection() {
    final facilities = _coachData!['facilities'] as List? ?? [];
    if (facilities.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Facilities & Programs', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: facilities.map((facility) {
            final isProgram = facility['type'] == 'program';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isProgram ? AppColors.infoLight : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isProgram ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isProgram ? LucideIcons.calendar : LucideIcons.building2,
                    size: 16,
                    color: isProgram ? AppColors.primary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    facility['name'] ?? '',
                    style: TextStyle(
                      color: isProgram ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildShowcaseAthletesSection() {
    final athletes = _coachData!['showcase_athletes'] as List? ?? [];
    if (athletes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Associated Athletes', style: Theme.of(context).textTheme.titleLarge),
            TextButton(
              onPressed: () {},
              child: const Text('See all →'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: athletes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final athlete = athletes[index];
              return Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: athlete['profile_photo_url'] != null
                        ? NetworkImage(MediaUtils.resolveUrl(athlete['profile_photo_url']))
                        : null,
                    backgroundColor: Colors.white,
                    child: athlete['profile_photo_url'] == null
                        ? const Icon(LucideIcons.user, color: AppColors.textTertiary)
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    athlete['name'] ?? 'Athlete',
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Contact Information', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (_coachData!['contact_number'] != null)
          _buildContactItem(
            icon: LucideIcons.phone,
            label: _coachData!['contact_number'],
            onTap: () {},
          ),
        if (_coachData!['email'] != null)
          _buildContactItem(
            icon: LucideIcons.mail,
            label: _coachData!['email'],
            onTap: () {},
          ),
      ],
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String? label,
    required VoidCallback onTap,
  }) {
    if (label == null) return const SizedBox.shrink();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.infoLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(LucideIcons.chevronRight, color: AppColors.textTertiary),
      onTap: onTap,
    );
  }

  Widget _buildShareProfileButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Share.share(
            'Check out this coach on SportX India!\nhttps://sportx.in/coach/${widget.coachId}',
          );
        },
        icon: const Icon(LucideIcons.share2),
        label: const Text('Share Profile'),
      ),
    );
  }

  Widget _buildBottomCTA() {
    final isPending = _connectionStatus == 'pending';
    final isConnected = _connectionStatus == 'accepted';

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: (_isConnecting || isPending || isConnected) ? null : _handleConnect,
                icon: _isConnecting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(isPending ? LucideIcons.hourglass : isConnected ? LucideIcons.check : LucideIcons.userPlus),
                label: Text(isPending ? 'Pending' : isConnected ? 'Connected' : 'Connect'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  context.push('/enquire/coach_profile/${widget.coachId}/${Uri.encodeComponent(_coachData!['full_name'] ?? 'Coach')}');
                },
                child: const Text('Enquire / Book'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
