import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/config/api_config.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/models/social_links.dart';
import 'package:sportx_app/shared/presentation/widgets/social_links.dart';
import 'package:sportx_app/shared/presentation/widgets/home_kit.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';

/// Own-profile screen — D.1 layout: profile hero + overlapping avatar,
/// stathead (5 stats + completion bar), bio, Edit/Share/Public actions,
/// tab strip and about/details / media / achievements cards.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoading = true;
  int _tab = 0;

  // Profile data
  int _userId = 0;
  String _name = '';
  String _bio = '';
  String _sport = '';
  String _ageGroup = '';
  String _location = '';
  bool _isVerified = false;
  final int _postsCount = 0;
  int _connectsCount = 0;
  int _achievementsCount = 0;
  int _sportsCount = 0;
  int _completionPercent = 0;

  List<Map<String, dynamic>> _achievements = [];

  String? _avatarUrl;
  String? _coverUrl;

  List<Map<String, dynamic>> _uploadedMedia = const [];

  Map<String, String> _socialLinks = const {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// "Get the blue check" CTA — shown until the verified badge is granted.
  Widget _verificationCta() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () => context.push('/verification'),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.verifiedBadge.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.verifiedBadge.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.badgeCheck,
                  size: 20, color: AppColors.verifiedBadge),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Get the blue check',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
              ),
              const Icon(LucideIcons.chevronRight,
                  size: 18, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadProfile() async {
    final authUser = ref.read(authProvider).user;
    if (mounted) {
      setState(() {
        _userId = authUser?.id ?? 0;
        if (_name.isEmpty) _name = authUser?.name ?? '';
        _isLoading = true;
      });
    }

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
        final cover = data['cover'] as Map<String, dynamic>?;
        final mediaItems = data['media_items'] as List? ?? const [];

        setState(() {
          _name = (data['full_name'] ?? data['name'] ?? _name) as String;
          _bio = (data['experience'] ?? data['bio'] ?? _bio) as String;
          _sport = sports.isNotEmpty ? ((sports[0] as Map)['name'] as String?) ?? _sport : _sport;
          _sportsCount = sports.length;
          _ageGroup = (ageGroup?['label'] ?? ageGroup?['name'] ?? _ageGroup) as String;
          _location = (city?['name'] ?? _location) as String;
          _isVerified = data['is_verified'] == true;
          _avatarUrl = photo?['url'] as String?;
          // Cover photo is its own slot — never derived from the media gallery
          // or the profile photo.
          _coverUrl = (cover?['url'] as String?) ?? (data['cover_image_url'] as String?);
          _socialLinks = socialLinksOf(Map<String, dynamic>.from(data as Map));
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
      if (mounted) SnackBarUtils.showError(context, e, 'Failed to load profile');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    _loadConnectionCount();
    _loadCompletionPercent();
  }

  Future<void> _loadCompletionPercent() async {
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.get('/me/home');
      final pct = (resp.data['data']?['completion_percent'] as num?)?.toInt();
      if (mounted && pct != null) {
        setState(() => _completionPercent = pct);
      }
    } catch (_) {
      // Home endpoint is athlete-only; silently skip for other roles.
    }
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
      backgroundColor: AppColors.surface,
      appBar: SportXTopBar(title: 'My Profile'),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: _isLoading
            ? const CoachProfileViewSkeleton()
            : ListView(
                padding: EdgeInsets.zero,
                children: [
                  _profileHero(),
                  _profileTitle(),
                  _statHead(),
                  if (!_isVerified) _verificationCta(),
                  const SizedBox(height: 8),
                  if (_bio.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Text(_bio,
                          style: GoogleFonts.inter(
                              fontSize: 11, height: 1.6, color: AppColors.textSecondary)),
                    ),
                  _profileActions(),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: KitTabBar(
                      labels: const ['Overview', 'Posts', 'Achv', 'Media', 'Conn.'],
                      activeIndex: _tab,
                      onChanged: (i) {
                        switch (i) {
                          case 1:
                            context.push('/activity-hub');
                            break;
                          case 2:
                            context.push('/achievements');
                            break;
                          case 3:
                            context.push('/media-gallery');
                            break;
                          case 4:
                            context.push('/my-connections');
                            break;
                        }
                        setState(() => _tab = 0);
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  _aboutCard(),
                  const SizedBox(height: 12),
                  _sportsCard(),
                  const SizedBox(height: 12),
                  _mediaCard(),
                  const SizedBox(height: 12),
                  _achievementsCard(),
                  const SizedBox(height: 12),
                  _socialCard(),
                  _roleQuickLinks(),
                  _accountActions(),
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }

  /// .profile-hero — full-bleed cover (166px) with the 84px avatar overlapping
  /// the bottom-left corner (white padding ring, bottom −42).
  Widget _profileHero() {
    // The cover is the explicitly-set banner photo. Gallery items never
    // become the cover on their own.
    final cover = _coverUrl != null && _coverUrl!.isNotEmpty ? _absoluteUrl(_coverUrl!) : '';
    Widget coverImg = Container(
      height: 166,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF3D6), AppColors.yellowTint, AppColors.surface],
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(LucideIcons.image, size: 28, color: AppColors.textTertiary),
    );
    if (cover.isNotEmpty) {
      coverImg = Image.network(cover,
          height: 166, width: double.infinity, fit: BoxFit.cover,
          errorBuilder: (_, _, _) => coverImg);
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        coverImg,
        Positioned(
          left: 16,
          bottom: -42,
          child: Container(
            width: 84,
            height: 84,
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Color(0x1A101415), blurRadius: 18, offset: Offset(0, 6)),
              ],
            ),
            child: ClipOval(
              child: _avatarUrl != null
                  ? Image.network(
                      _absoluteUrl(_avatarUrl!),
                      width: 78,
                      height: 78,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _FallbackAvatar(),
                    )
                  : const _FallbackAvatar(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 42, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(_name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
            ),
            if (_isVerified) const Icon(LucideIcons.badgeCheck, size: 16, color: AppColors.primary),
          ]),
          const SizedBox(height: 5),
          Text(_ageGroup.isNotEmpty ? '$_sport Player • $_ageGroup' : _sport.isNotEmpty ? '$_sport Player • Athlete' : 'Athlete',
              style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(height: 5),
          Row(children: [
            const Icon(LucideIcons.mapPin, size: 13, color: AppColors.yellowDeep),
            const SizedBox(width: 4),
            Text(_location,
                style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
          ]),
        ],
      ),
    );
  }

  /// .stathead — gradient card, 5-count grid + completion bar.
  Widget _statHead() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment(-0.4, -1),
            end: Alignment(0.4, 1),
            colors: [Colors.white, AppColors.yellowSoft],
          ),
          border: Border.all(color: const Color(0xFFF0E3B2)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _stat('$_postsCount', 'Posts'),
                _stat('$_connectsCount', 'Connections'),
                _stat('$_sportsCount', 'Sports'),
                _stat('$_achievementsCount', 'Achieve.'),
                _stat('$_completionPercent%', 'Complete'),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: Container(
                height: 6,
                color: AppColors.surface,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (_completionPercent.clamp(0, 100)) / 100,
                  child: Container(color: AppColors.yellow),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 9, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  /// .profile-actions — Edit (primary) + Share/Public chips.
  Widget _profileActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                await context.push('/edit-profile');
                _loadProfile();
              },
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFD54A), AppColors.yellow, Color(0xFFF5B400)],
                  ),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: const Color(0x2E785000)),
                  boxShadow: SportXShadows.btnShadow,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.pencil, size: 14, color: AppColors.ink),
                    const SizedBox(width: 6),
                    Text('Edit',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SportXChip(label: 'Share', onTap: _shareProfile),
          const SizedBox(width: 8),
          SportXChip(label: 'Public', onTap: () => context.push('/view-as-public')),
        ],
      ),
    );
  }

  void _shareProfile() {
    final shareUrl = '${ApiConfig.webBaseUrl}/profile/$_userId';
    Share.share('Check out my profile on SportX India!\n$shareUrl');
  }

  Widget _card({required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
          boxShadow: SportXShadows.e1,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    );
  }

  Widget _inCardSection(String title, {Widget? action}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(title,
              style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const Spacer(),
          ?action,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
          const Spacer(),
          Flexible(
            child: Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.ink)),
          ),
        ],
      ),
    );
  }

  Widget _aboutCard() {
    return _card(children: [
      _inCardSection('👤 About'),
      _detailRow('Full Name', _name),
      _detailRow('Role', _sport.isNotEmpty ? '$_sport Player' : 'Athlete'),
      _detailRow('Location', _location),
      if (_ageGroup.isNotEmpty) _detailRow('Age Group', _ageGroup),
      if (_bio.trim().isEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('No bio yet — add one from Edit profile.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ),
    ]);
  }

  Widget _sportsCard() {
    if (_sport.isEmpty) return const SizedBox.shrink();
    return _card(children: [
      _inCardSection('🏏 Sports'),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text('🏏 $_sport',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.yellowTint,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text('Primary Sport',
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF8A6D00))),
              ),
            ]),
            if (_ageGroup.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Age group · $_ageGroup',
                  style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ],
        ),
      ),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: () => context.push('/manage-sports'),
        behavior: HitTestBehavior.opaque,
        child: Text('+ Add Another Sport',
            style: GoogleFonts.inter(
                fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF8A6D00))),
      ),
    ]);
  }

  Widget _mediaCard() {
    final images = _uploadedMedia
        .map((m) => _absoluteUrl((m['url'] ?? '') as String))
        .where((u) => u.isNotEmpty)
        .toList();
    return _card(children: [
      _inCardSection('📷 Media', action: _cardAction('See all', () async {
        await context.push('/media-gallery');
        _loadProfile();
      })),
      const SizedBox(height: 8),
      if (images.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: Text('No media yet — add photos from your gallery.',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
          ),
        )
      else
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            mainAxisExtent: 76,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: images.length.clamp(0, 6),
          itemBuilder: (context, index) {
            if (index == 5 && images.length > 6) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text('+${images.length - 5}',
                    style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
              );
            }
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                images[index],
                height: 76,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.surface,
                  child: const Icon(LucideIcons.image, size: 18, color: AppColors.textSecondary),
                ),
              ),
            );
          },
        ),
    ]);
  }

  Widget _achievementsCard() {
    return _card(children: [
      _inCardSection('🏆 Achievements', action: _cardAction('Add', () => context.push('/add-achievement'))),
      if (_achievements.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: Text('No achievements yet — add your first one.',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
          ),
        )
      else
        ..._achievements.map((a) => Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.borderSoft)),
              ),
              child: Row(
                children: [
                  Text(a['icon'] ?? '🏆', style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(a['title'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  ),
                  if ((a['year'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(a['year'],
                        style: GoogleFonts.inter(fontSize: 9, color: AppColors.textSecondary)),
                  ],
                  const SizedBox(width: 4),
                  const Icon(LucideIcons.chevronRight, size: 14, color: AppColors.textTertiary),
                ],
              ),
            )),
    ]);
  }

  Widget _socialCard() {
    return _card(children: [
      _inCardSection('🔗 Social Links', action: _cardAction(_socialLinks.isEmpty ? 'Add' : 'Edit', () async {
        await context.push('/social-links');
        _loadProfile();
      })),
      const SizedBox(height: 8),
      if (_socialLinks.isEmpty)
        const Text('No social links yet. Add them so others can find you.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary))
      else
        SocialLinksRow(links: _socialLinks),
    ]);
  }

  Widget _cardAction(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text('$label ›',
          style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF8A6D00))),
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

  Widget _roleQuickLinks() {
    final role = ref.watch(authProvider).user?.role ?? 'athlete';
    final links = _quickLinksForRole(role);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
          boxShadow: SportXShadows.e1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _inCardSection(_roleTitle(role)),
            GridView.count(
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
                      border: Border.all(color: AppColors.borderSoft),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(l.icon, color: AppColors.yellowDeep, size: 22),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            l.label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accountActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          SharedOutlinedAction(
            label: 'Settings',
            icon: LucideIcons.settings,
            onPressed: () => context.push('/settings'),
            foregroundColor: AppColors.textPrimary,
          ),
          const SizedBox(height: 10),
          SharedOutlinedAction(
            label: 'Log out',
            icon: LucideIcons.logOut,
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
            },
            foregroundColor: AppColors.error,
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
        // Legacy role (removed server-side): route to unified opportunities.
        return const [
          _QuickLink('Opportunities', '/opportunities', LucideIcons.layoutDashboard),
          _QuickLink('My Opportunities', '/my-opportunities', LucideIcons.list),
          _QuickLink('Activity', '/activity-hub', LucideIcons.activity),
        ];
      default: // athlete
        return const [
          _QuickLink('Edit Profile', '/edit-profile', LucideIcons.edit2),
          _QuickLink('Media', '/media-gallery', LucideIcons.image),
          _QuickLink('Activity', '/activity-hub', LucideIcons.activity),
          _QuickLink('Opportunities', '/opportunities', LucideIcons.graduationCap),
          _QuickLink('Tournaments', '/tournament-calendar', LucideIcons.calendar),
          _QuickLink('Connections', '/my-connections', LucideIcons.users),
        ];
    }
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      alignment: Alignment.center,
      child: const Icon(LucideIcons.user, size: 34, color: AppColors.ink),
    );
  }
}

/// Ghost action row shared by Settings / Logout.
class SharedOutlinedAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Future<void> Function() onPressed;
  final Color foregroundColor;
  const SharedOutlinedAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => onPressed(),
      style: OutlinedButton.styleFrom(
        foregroundColor: foregroundColor,
        side: BorderSide(color: foregroundColor == AppColors.error ? AppColors.error : AppColors.border),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }
}

class _QuickLink {
  final String label;
  final String route;
  final IconData icon;
  const _QuickLink(this.label, this.route, this.icon);
}
