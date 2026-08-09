import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/theme/colors.dart';

class ViewProfileScreen extends ConsumerStatefulWidget {
  final String type;
  final String id;

  const ViewProfileScreen({
    super.key,
    required this.type,
    required this.id,
  });

  @override
  ConsumerState<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends ConsumerState<ViewProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final dio = ref.read(dioProvider);
      final endpoint = widget.type == 'coach'
          ? '/coaches/${widget.id}'
          : '/athletes/${widget.id}';
      final response = await dio.get(endpoint);
      if (mounted) {
        setState(() {
          _profileData = response.data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _profileData = _getMockData();
        });
      }
    }
  }

  Map<String, dynamic> _getMockData() {
    if (widget.type == 'coach') {
      return {
        'full_name': 'Coach Rahul Mehta',
        'profile_photo_url': 'https://i.pravatar.cc/150?img=10',
        'specialization': 'Cricket',
        'experience': 8,
        'bio': 'Passionate cricket coach with 8 years of experience.',
        'city': {'name': 'Ahmedabad'},
        'is_verified': true,
      };
    }
    return {
      'name': 'Aryan Patel',
      'profile_photo_url': 'https://i.pravatar.cc/150?img=11',
      'sport': {'name': 'Cricket'},
      'bio': 'Passionate cricketer from Ahmedabad.',
      'city': {'name': 'Ahmedabad'},
      'age_group': 'Under-14',
      'is_verified': true,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profileData == null
              ? const Center(child: Text('Profile not found'))
              : CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(),
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildProfileInfo(),
                          const SizedBox(height: 24),
                          _buildActionButtons(),
                          const SizedBox(height: 24),
                          _buildStatsRow(),
                          const SizedBox(height: 24),
                          _buildAboutSection(),
                          const SizedBox(height: 24),
                          _buildAchievementsSection(),
                          const SizedBox(height: 24),
                          if (widget.type == 'athlete') ...[
                            _buildTournamentHistorySection(),
                            const SizedBox(height: 24),
                            _buildPerformanceStatsSection(),
                            const SizedBox(height: 24),
                          ],
                          _buildMediaGallerySection(),
                          const SizedBox(height: 24),
                          _buildSocialLinksSection(),
                          const SizedBox(height: 100),
                        ]),
                      ),
                    ),
                  ],
                ),
      bottomSheet: _profileData != null ? _buildBottomActions() : null,
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
            Image.network(
              'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800&h=400&fit=crop',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
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
                    backgroundImage: _profileData!['profile_photo_url'] != null
                        ? NetworkImage(_profileData!['profile_photo_url'])
                        : null,
                    backgroundColor: AppColors.surface,
                    child: _profileData!['profile_photo_url'] == null
                        ? const Icon(Icons.person, size: 40, color: AppColors.textTertiary)
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
                              _profileData!['name'] ?? _profileData!['full_name'] ?? 'Profile',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_profileData!['is_verified'] == true) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified, color: AppColors.primary, size: 20),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getSubtitle(),
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
          icon: const Icon(Icons.favorite_border, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () {
            Share.share(
              'Check out this profile on SportX India!\nhttps://sportx.in/profile/${widget.id}',
            );
          },
        ),
      ],
    );
  }

  String _getSubtitle() {
    if (widget.type == 'coach') {
      return '${_profileData!['specialization'] ?? "Coach"} · ${_profileData!['city']?['name'] ?? "India"}';
    }
    return '${_profileData!['sport']?['name'] ?? "Athlete"} · ${_profileData!['city']?['name'] ?? "India"}';
  }

  Widget _buildProfileInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.type == 'athlete') ...[
          Row(
            children: [
              Icon(Icons.cake_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                _profileData!['age_group'] ?? 'N/A',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ] else ...[
          Row(
            children: [
              Icon(Icons.work_outline, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${_profileData!['experience'] ?? 0} years experience',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.person_add),
            label: const Text('Connect'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              context.push('/chat-screen', extra: {
                'id': widget.id,
                'name': _profileData!['name'] ?? _profileData!['full_name'] ?? 'Profile',
                'avatar': _profileData!['profile_photo_url'],
              });
            },
            icon: const Icon(Icons.chat),
            label: const Text('Message'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('24', 'Posts', Icons.post_add_outlined),
          Container(width: 1, height: 32, color: AppColors.border),
          _buildStatItem('156', 'Connects', Icons.people_outline),
          Container(width: 1, height: 32, color: AppColors.border),
          _buildStatItem('8', 'Achievements', Icons.emoji_events_outlined),
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
          _profileData!['bio'] ?? 'No bio available.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildAchievementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Achievements', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _buildAchievementItem('🏆', 'State-level U-14 Selection', '2025'),
        _buildAchievementItem('🥇', 'District Top Scorer', '2024'),
        _buildAchievementItem('🏏', 'Best Batsman Award', '2024'),
      ],
    );
  }

  Widget _buildAchievementItem(String icon, String title, String year) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(year, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tournament History', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _buildTournamentItem('Gujarat State U-14 Championship', '2025', 'Semi-finalist'),
        _buildTournamentItem('Ahmedabad District Cricket League', '2024', 'Winner'),
      ],
    );
  }

  Widget _buildTournamentItem(String name, String year, String result) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.emoji_events_outlined, color: AppColors.cta),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text('$year · $result', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Performance Stats', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2,
          children: [
            _buildPerformanceStat('42', 'Matches'),
            _buildPerformanceStat('1,250', 'Runs'),
            _buildPerformanceStat('35.7', 'Average'),
            _buildPerformanceStat('12', 'Wickets'),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildMediaGallerySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Media Gallery', style: Theme.of(context).textTheme.titleLarge),
            TextButton(
              onPressed: () {},
              child: const Text('See all →'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage('https://picsum.photos/400/400?random=${index + 10}'),
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSocialLinksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Social Links', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _buildSocialLink(Icons.language, 'Website', 'https://example.com'),
        _buildSocialLink(Icons.camera_alt, 'Instagram', '@username'),
        _buildSocialLink(Icons.play_circle, 'YouTube', 'Channel Name'),
      ],
    );
  }

  Widget _buildSocialLink(IconData icon, String platform, String handle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.infoLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(platform, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(handle),
      trailing: const Icon(Icons.open_in_new, size: 18, color: AppColors.textTertiary),
      onTap: () {},
    );
  }

  Widget _buildBottomActions() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.person_add),
                label: const Text('Connect'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  context.push('/chat-screen', extra: {
                    'id': widget.id,
                    'name': _profileData!['name'] ?? _profileData!['full_name'] ?? 'Profile',
                    'avatar': _profileData!['profile_photo_url'],
                  });
                },
                icon: const Icon(Icons.chat),
                label: const Text('Message'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
