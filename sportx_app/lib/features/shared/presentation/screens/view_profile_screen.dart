import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/social_links.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';

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

  // Athlete-to-athlete connect state (generic Connection graph).
  String? _connStatus; // none | pending | accepted
  bool _connIsInitiator = true;
  bool _connLoading = false;
  bool _connecting = false;
  bool _openingChat = false;

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
        _loadConnStatus();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _profileData = null;
        });
        SnackBarUtils.showError(context, ApiException.fromDio(e is DioException ? e : DioException(requestOptions: RequestOptions(path: ''), error: e)));
      }
    }
  }

  /// user_id of the profile being viewed (athlete/coach payloads embed `user`).
  String? get _profileUserId {
    final u = _profileData?['user'];
    if (u is Map && u['id'] != null) return u['id'].toString();
    return _profileData?['user_id']?.toString();
  }

  bool get _isOwnProfile {
    final me = ref.read(authProvider).user?.id.toString();
    return me != null && _profileUserId != null && me == _profileUserId;
  }

  /// Load generic connection status for athlete-to-athlete connect/chat.
  Future<void> _loadConnStatus() async {
    if (widget.type != 'athlete' || _profileUserId == null || _isOwnProfile) return;
    setState(() => _connLoading = true);
    try {
      final resp = await ref.read(dioProvider).get('/me/connections/status/$_profileUserId');
      if (!mounted) return;
      final data = resp.data['data'] as Map<String, dynamic>?;
      setState(() {
        _connStatus = data?['status']?.toString() ?? 'none';
        _connIsInitiator = data?['is_initiator'] != false;
        _connLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _connLoading = false);
    }
  }

  Future<void> _handleConnect() async {
    if (_profileUserId == null) return;
    setState(() => _connecting = true);
    try {
      await ref.read(dioProvider).post('/me/connections/request', data: {'user_id': int.parse(_profileUserId!)});
      if (!mounted) return;
      SnackBarUtils.showSuccess(context, 'Connection request sent');
      await _loadConnStatus();
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.data?['error']?['code']?.toString();
      final msg = e.response?.data?['error']?['message']?.toString();
      if (code == 'CONFLICT') {
        SnackBarUtils.showError(context, 'Request already sent');
        await _loadConnStatus();
      } else {
        SnackBarUtils.showError(context, msg ?? 'Could not send request');
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _handleMessage() async {
    if (_profileUserId == null) return;
    setState(() => _openingChat = true);
    try {
      final (chatId, err) = await startConversationResult(ref, int.parse(_profileUserId!));
      if (!mounted) return;
      if (chatId != null) {
        context.push('/chat-screen', extra: {
          'id': chatId,
          'name': _profileData!['name'] ?? _profileData!['full_name'] ?? 'Profile',
          'avatar': _profileData!['profile_photo_url'],
        });
      } else {
        SnackBarUtils.showError(context, err ?? 'Could not open chat');
      }
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  Widget _connectButton({bool expanded = true}) {
    final btn = _connLoading
        ? const OutlinedButton(onPressed: null, child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)))
        : _connStatus == 'accepted'
            ? FilledButton.icon(onPressed: () => context.push('/my-connections'), icon: const Icon(Icons.check, size: 18), label: const Text('Connected'))
            : _connStatus == 'pending'
                ? OutlinedButton.icon(onPressed: _connIsInitiator ? null : () => context.push('/connection-requests'), icon: const Icon(Icons.hourglass_empty, size: 18), label: Text(_connIsInitiator ? 'Request Sent' : 'Respond'))
                : ElevatedButton.icon(
                    onPressed: _connecting ? null : _handleConnect,
                    icon: _connecting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.person_add, size: 18),
                    label: const Text('Connect'),
                  );
    return expanded ? Expanded(child: btn) : btn;
  }

  Widget _messageButton({bool expanded = true}) {
    final btn = OutlinedButton.icon(
      onPressed: _openingChat ? null : _handleMessage,
      icon: _openingChat
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.chat),
      label: const Text('Message'),
    );
    return expanded ? Expanded(child: btn) : btn;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const GenericDetailSkeleton()
          : _profileData == null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    const Text('Profile not found or unavailable'),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _loadProfile, child: const Text('Retry')),
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
                          _buildActionButtons(),
                          const SizedBox(height: 24),
                          _buildStatsRow(),
                          const SizedBox(height: 24),
                          _buildAboutSection(),
                          const SizedBox(height: 24),
                          _buildAchievementsSection(),
                          const SizedBox(height: 24),
                          // Tournament history / stats only if backend provides data; hide otherwise to avoid fake UI
                          if (widget.type == 'athlete' && (_profileData!['tournament_history'] is List && (_profileData!['tournament_history'] as List).isNotEmpty)) ...[
                            _buildTournamentHistorySection(),
                            const SizedBox(height: 24),
                          ],
                          if (widget.type == 'athlete' && (_profileData!['performance_stats'] is List && (_profileData!['performance_stats'] as List).isNotEmpty)) ...[
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
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E3A5F), Color(0xFF2E5A8F)],
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
                    backgroundImage: _profileData!['profile_photo_url'] != null
                        ? NetworkImage(MediaUtils.resolveUrl(_profileData!['profile_photo_url'].toString()))
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
    // Athlete-to-athlete connect + chat. Other profile types keep Message only.
    final showConnect = widget.type == 'athlete' && !_isOwnProfile && _profileUserId != null;
    return Row(
      children: [
        if (showConnect) ...[
          _connectButton(),
          const SizedBox(width: 12),
        ],
        _messageButton(),
      ],
    );
  }

  Widget _buildStatsRow() {
    final connectionsCount = _profileData!['connections_count'] ?? 0;
    final postsCount = _profileData!['posts_count'] ?? _profileData!['social_posts_count'] ?? 0;
    final achievementsCount = (_profileData!['achievements'] as List?)?.length ?? 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('$postsCount', 'Posts', Icons.post_add_outlined),
          Container(width: 1, height: 32, color: AppColors.border),
          _buildStatItem('$connectionsCount', 'Connects', Icons.people_outline),
          Container(width: 1, height: 32, color: AppColors.border),
          _buildStatItem('$achievementsCount', 'Achievements', Icons.emoji_events_outlined),
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
    final achievements = _profileData!['achievements'] as List? ?? [];
    if (achievements.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Achievements', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...achievements.map((a) {
          final m = a is Map ? a : {'text': a.toString()};
          return _buildAchievementItem('🏆', (m['text'] ?? m['title'] ?? '').toString(), (m['year'] ?? '').toString());
        }),
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
    final mediaItems = _profileData!['media_items'] as List? ?? [];
    if (mediaItems.isEmpty) return const SizedBox.shrink();
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
          itemCount: mediaItems.length.clamp(0, 6),
          itemBuilder: (context, index) {
            final item = mediaItems[index] is Map ? mediaItems[index] as Map : {};
            final url = MediaUtils.resolveNullable((item['url'] ?? item['media_url'])?.toString());
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.surface,
                image: url != null ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover) : null,
              ),
              child: url == null ? const Icon(Icons.image, color: AppColors.textSecondary) : null,
            );
          },
        ),
      ],
    );
  }

  Widget _buildSocialLinksSection() {
    // Real links from the profile payload (user.social_links); hidden when empty.
    return SocialLinksSection(profile: _profileData);
  }

  Widget _buildBottomActions() {
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
            if (widget.type == 'athlete' && !_isOwnProfile && _profileUserId != null) ...[
              _connectButton(),
              const SizedBox(width: 12),
            ],
            _messageButton(),
          ],
        ),
      ),
    );
  }
}