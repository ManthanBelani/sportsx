import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/config/api_config.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoading = true;

  // Profile data
  int _userId = 0;
  String _name = '';
  String _bio = '';
  String _sport = '';
  String _ageGroup = '';
  String _location = '';
  bool _isVerified = false;
  int _postsCount = 0;
  int _connectsCount = 0;
  int _achievementsCount = 0;

  List<Map<String, dynamic>> _achievements = [];

  String? _avatarUrl;

  List<Map<String, dynamic>> _uploadedMedia = const [];

  List<Map<String, dynamic>> _tournamentHistory = [];

  List<Map<String, dynamic>> _performanceStats = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final authUser = ref.read(authProvider).user;
    setState(() {
      _userId = authUser?.id ?? 0;
      _name = authUser?.name ?? '';
      _isLoading = false;
    });

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/me/profile');
      final data = response.data['data'];

      if (mounted && data != null) {
        final sports = data['sports'] as List? ?? const [];
        final ageGroup = (data['age_group'] ?? data['ageGroup']) as Map<String, dynamic>?;
        final city = data['city'] as Map<String, dynamic>?;
        final ach = data['achievements'] as List? ?? const [];
        final photo = data['photo'] as Map<String, dynamic>?;
        final mediaItems = data['media_items'] as List? ?? const [];

        setState(() {
          _name = (data['full_name'] ?? data['name'] ?? _name) as String;
          _bio = (data['experience'] ?? data['bio'] ?? _bio) as String;
          _sport = sports.isNotEmpty ? ((sports[0] as Map)['name'] as String?) ?? _sport : _sport;
          _ageGroup = (ageGroup?['label'] ?? ageGroup?['name'] ?? _ageGroup) as String;
          _location = (city?['name'] ?? _location) as String;
          _isVerified = data['is_verified'] == true;
          _avatarUrl = photo?['url'] as String?;
          _uploadedMedia = mediaItems
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList();
          _achievementsCount = ach.isNotEmpty ? ach.length : _achievementsCount;
          if (ach.isNotEmpty) {
            _achievements = ach.asMap().entries.map((e) {
              final text = (e.value as Map)['text'] ?? '';
              return <String, dynamic>{
                'id': e.key.toString(),
                'title': text.toString(),
                'year': '',
                'icon': '🏆',
              };
            }).toList();
          }
        });
      }
    } catch (e) {
      debugPrint('Failed to load profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    _loadConnectionCount();
  }

  Future<void> _loadConnectionCount() async {
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.get('/me/connections/count');
      if (mounted) {
        setState(() {
          _connectsCount = resp.data['data']['count'] as int? ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Failed to load connection count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('My Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.edit2, color: AppColors.primary, size: 20),
            onPressed: () async {
              await context.push('/edit-profile');
              _loadProfile();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProfileHeader(),
                    _buildSectionDivider(),
                    _buildAboutSection(),
                    _buildSectionDivider(),
                    _buildAchievementsSection(),
                    _buildSectionDivider(),
                    _buildTournamentHistorySection(),
                    _buildSectionDivider(),
                    _buildPerformanceStatsSection(),
                    _buildSectionDivider(),
                    _buildMediaGallerySection(),
                    _buildSectionDivider(),
                    _buildShareProfileButton(),
                    _buildSectionDivider(),
                    _buildRoleQuickLinks(),
                    _buildAccountActions(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionDivider() {
    return Container(
      height: 8,
      color: AppColors.surface,
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary, Color(0xFF0d47a1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ClipOval(
              child: _avatarUrl != null
                  ? Image.network(
                      _absoluteUrl(_avatarUrl!),
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(LucideIcons.user, size: 48, color: Colors.white),
                    )
                  : const Icon(LucideIcons.user, size: 48, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _name,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              if (_isVerified) ...[
                const SizedBox(width: 4),
                const Icon(LucideIcons.badgeCheck, color: AppColors.primary, size: 20),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$_sport • $_ageGroup',
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.mapPin, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                _location,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeaderStatItem('$_postsCount', 'Posts'),
              const SizedBox(width: 32),
              _buildHeaderStatItem('$_connectsCount', 'Connects'),
              const SizedBox(width: 32),
              _buildHeaderStatItem('$_achievementsCount', 'Achievements'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSection(
      title: 'About',
      child: Text(
        _bio,
        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
      ),
    );
  }

  Widget _buildAchievementsSection() {
    return _buildSection(
      title: 'Achievements',
      action: GestureDetector(
        onTap: () => context.push('/add-achievement'),
        child: const Text('Add', style: TextStyle(fontSize: 13, color: AppColors.primary)),
      ),
      child: Column(
        children: _achievements.map((achievement) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(achievement['icon'], style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement['title'],
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        achievement['year'],
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTournamentHistorySection() {
    if (_tournamentHistory.isEmpty) {
      return _buildSection(
        title: 'Tournament History',
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                const Icon(LucideIcons.trophy, size: 40, color: AppColors.textSecondary),
                const SizedBox(height: 12),
                const Text(
                  'No tournament history yet',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Register for trials and tournaments to build your history',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withOpacity(0.7)),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return _buildSection(
      title: 'Tournament History',
      child: Column(
        children: _tournamentHistory.map((tournament) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(tournament['icon'] ?? '🏆', style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tournament['name'] ?? '',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${tournament['year'] ?? ''} • ${tournament['result'] ?? ''}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPerformanceStatsSection() {
    if (_performanceStats.isEmpty) {
      return _buildSection(
        title: 'Performance Stats',
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                const Icon(LucideIcons.barChart3, size: 40, color: AppColors.textSecondary),
                const SizedBox(height: 12),
                const Text(
                  'No stats available',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your performance stats will appear here after tournaments',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withOpacity(0.7)),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return _buildSection(
      title: 'Performance Stats',
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.2,
        padding: EdgeInsets.zero,
        children: _performanceStats.map((stat) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  stat['value'] ?? '0',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
                Text(
                  stat['label'] ?? '',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMediaGallerySection() {
    final images = _uploadedMedia
        .map((m) => _absoluteUrl((m['url'] ?? '') as String))
        .where((u) => u.isNotEmpty)
        .toList();

    return _buildSection(
      title: 'Media Gallery',
      action: GestureDetector(
        onTap: () async {
          await context.push('/media-gallery');
          _loadProfile();
        },
        child: const Text('See all', style: TextStyle(fontSize: 13, color: AppColors.primary)),
      ),
      child: images.isEmpty
          ? Container(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    const Icon(LucideIcons.image, size: 40, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    const Text(
                      'No media yet',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add photos and videos to your gallery',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
            )
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: images.length,
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    images[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surface,
                      child: const Icon(LucideIcons.image, color: AppColors.textSecondary),
                    ),
                  ),
                );
              },
            ),
    );
  }

  /// Media URLs from the API may be root-relative (/storage/…) — make them
  /// absolute against the configured API host.
  String _absoluteUrl(String url) {
    if (url.isEmpty || url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final base = ref.read(dioProvider).options.baseUrl;
    final origin = base.replaceFirst(RegExp(r'/api/v1/?$'), '');
    return '$origin$url';
  }

  Widget _buildShareProfileButton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: () {
            final shareUrl = '${ApiConfig.webBaseUrl}/profile/$_userId';
            Share.share(
              'Check out my profile on SportX India!\n$shareUrl',
            );
          },
          icon: const Icon(LucideIcons.share2, size: 20),
          label: const Text('Share Profile', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleQuickLinks() {
    final role = ref.watch(authProvider).user?.role ?? 'athlete';
    final links = _quickLinksForRole(role);
    return _buildSection(
      title: _roleTitle(role),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
        padding: EdgeInsets.zero,
        children: links.map((l) {
          return GestureDetector(
            onTap: () => context.push(l.route),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(l.icon, color: AppColors.primary, size: 24),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      l.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                    ),
                  ),
                ],
                ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAccountActions() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
         OutlinedButton.icon(
              onPressed: () => context.push('/settings'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.border),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(LucideIcons.settings, size: 18),
              label: const Text('Settings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(LucideIcons.logOut, size: 18),
              label: const Text('Log out', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  String _roleTitle(String role) {
    switch (role) {
      case 'coach': return 'Coach Tools';
      case 'academy': return 'Academy Tools';
      case 'organizer': return 'Organizer Tools';
      case 'sponsor': return 'Sponsor Tools';
      default: return 'Quick Links';
    }
  }

  List<_QuickLink> _quickLinksForRole(String role) {
    switch (role) {
      case 'coach':
        return const [
          _QuickLink('Dashboard', '/coach-dashboard', LucideIcons.layoutDashboard),
          _QuickLink('Edit Profile', '/edit-coach-profile', LucideIcons.edit2),
          _QuickLink('Post Trial', '/post-trial', LucideIcons.plusCircle),
          _QuickLink('My Trials', '/my-trials', LucideIcons.list),
          _QuickLink('Enquiries', '/enquiry-inbox', LucideIcons.inbox),
          _QuickLink('Activity', '/activity-hub', LucideIcons.activity),
        ];
      case 'academy':
        return const [
          _QuickLink('Dashboard', '/academy-dashboard', LucideIcons.layoutDashboard),
          _QuickLink('Edit Profile', '/edit-academy-profile', LucideIcons.edit2),
          _QuickLink('Post Trial', '/post-trial', LucideIcons.plusCircle),
          _QuickLink('My Trials', '/my-trials', LucideIcons.list),
          _QuickLink('Enquiries', '/enquiry-inbox', LucideIcons.inbox),
          _QuickLink('Activity', '/activity-hub', LucideIcons.activity),
        ];
      case 'organizer':
        return const [
          _QuickLink('Dashboard', '/organizer-dashboard', LucideIcons.layoutDashboard),
          _QuickLink('Post Event', '/post-tournament', LucideIcons.plusCircle),
          _QuickLink('My Events', '/my-tournaments', LucideIcons.list),
          _QuickLink('Activity', '/activity-hub', LucideIcons.activity),
          _QuickLink('Saved', '/saved', LucideIcons.bookmark),
          _QuickLink('Search', '/universal-search', LucideIcons.search),
        ];
      case 'sponsor':
        return const [
          _QuickLink('Dashboard', '/sponsor-dashboard', LucideIcons.layoutDashboard),
          _QuickLink('Post Sponsor', '/sponsor-posting', LucideIcons.plusCircle),
          _QuickLink('Discover', '/athlete-discovery', LucideIcons.search),
          _QuickLink('Shortlist', '/shortlist', LucideIcons.star),
          _QuickLink('Applications', '/applications-inbox', LucideIcons.inbox),
          _QuickLink('My Listings', '/my-sponsorships', LucideIcons.list),
        ];
      default: // athlete
        return const [
          _QuickLink('Edit Profile', '/edit-profile', LucideIcons.edit2),
          _QuickLink('Media', '/media-gallery', LucideIcons.image),
          _QuickLink('Activity', '/activity-hub', LucideIcons.activity),
          _QuickLink('Scholarships', '/scholarships', LucideIcons.graduationCap),
          _QuickLink('Venues', '/sports-venues', LucideIcons.mapPin),
          _QuickLink('Connections', '/my-connections', LucideIcons.users),
        ];
    }
  }

  Widget _buildSection({
    required String title,
    Widget? action,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _QuickLink {
  final String label;
  final String route;
  final IconData icon;
  const _QuickLink(this.label, this.route, this.icon);
}
