import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/theme/colors.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoading = true;

  // Profile data
  String _name = 'Aryan Patel';
  String _bio = 'Passionate cricketer from Ahmedabad. Looking for opportunities to grow and learn from the best in the game. Dedicated to improving my skills every day.';
  String _sport = 'Cricket';
  String _ageGroup = 'U-14';
  String _location = 'Ahmedabad, Gujarat';
  bool _isVerified = true;
  int _postsCount = 24;
  int _connectsCount = 156;
  int _achievementsCount = 8;

  final List<Map<String, dynamic>> _achievements = [
    {
      'id': '1',
      'title': 'State-level U-14 Selection',
      'year': '2025',
      'icon': '🏆',
    },
    {
      'id': '2',
      'title': 'District Top Scorer',
      'year': '2024',
      'icon': '🥇',
    },
    {
      'id': '3',
      'title': 'Best Batsman Award',
      'year': '2024',
      'icon': '🏏',
    },
  ];

  final List<Map<String, dynamic>> _tournamentHistory = [
    {
      'id': '1',
      'name': 'Gujarat State U-14 Championship',
      'year': '2025',
      'result': 'Semi-finalist',
      'icon': '🏆',
    },
    {
      'id': '2',
      'name': 'Ahmedabad District Cricket League',
      'year': '2024',
      'result': 'Winner',
      'icon': '🥇',
    },
  ];

  final List<Map<String, dynamic>> _performanceStats = [
    {'label': 'Matches', 'value': '42'},
    {'label': 'Runs', 'value': '1,250'},
    {'label': 'Average', 'value': '35.7'},
    {'label': 'Wickets', 'value': '12'},
  ];

  final List<String> _mediaGallery = [
    'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=200&h=200&fit=crop',
    'https://images.unsplash.com/photo-1518605368461-1ee7e53c23cb?w=200&h=200&fit=crop',
    'https://images.unsplash.com/photo-1587280501635-6cb10ee2d133?w=200&h=200&fit=crop',
    'https://images.unsplash.com/photo-1593341646782-e0b495cff86d?w=200&h=200&fit=crop',
    'https://images.unsplash.com/photo-1516130441908-16e917d23f33?w=200&h=200&fit=crop',
    'https://images.unsplash.com/photo-1624526267942-ab0f0b580898?w=200&h=200&fit=crop',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/me/profile');
      final data = response.data['data'];

      if (mounted && data != null) {
        setState(() {
          _name = data['name'] ?? _name;
          _bio = data['bio'] ?? _bio;
          _sport = data['primary_sport'] ?? _sport;
          _ageGroup = data['age_group'] ?? _ageGroup;
          _location = data['location'] ?? _location;
          _isVerified = data['is_verified'] == true;
          _postsCount = data['posts_count'] ?? _postsCount;
          _connectsCount = data['connects_count'] ?? _connectsCount;
          _achievementsCount = data['achievements_count'] ?? _achievementsCount;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
            onPressed: () => context.push('/edit-athlete-profile'),
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
            child: const Icon(LucideIcons.user, size: 48, color: Colors.white),
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
                  child: Text(tournament['icon'], style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tournament['name'],
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${tournament['year']} • ${tournament['result']}',
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
                  stat['value'],
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
                Text(
                  stat['label'],
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
    return _buildSection(
      title: 'Media Gallery',
      action: GestureDetector(
        onTap: () => context.push('/media-gallery'),
        child: const Text('See all', style: TextStyle(fontSize: 13, color: AppColors.primary)),
      ),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: _mediaGallery.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              _mediaGallery[index],
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }

  Widget _buildShareProfileButton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: () {
            Share.share(
              'Check out my profile on SportX India!\nhttps://sportx.in/profile/$_name',
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
