import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/scout_connection_provider.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/scout_shortlist_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';

class TalentScoutAthleteProfileViewScreen extends ConsumerStatefulWidget {
  final String athleteId;
  const TalentScoutAthleteProfileViewScreen({super.key, required this.athleteId});

  @override
  ConsumerState<TalentScoutAthleteProfileViewScreen> createState() => _TalentScoutAthleteProfileViewScreenState();
}

class _TalentScoutAthleteProfileViewScreenState extends ConsumerState<TalentScoutAthleteProfileViewScreen> {
  Map<String, dynamic>? _athlete;
  bool _isLoading = true;
  String? _error;
  bool _isShortlisted = false;

  @override
  void initState() {
    super.initState();
    _loadAthlete();
    Future.microtask(() => ref.read(scoutConnectionProvider.notifier).load());
  }

  Future<void> _loadAthlete() async {
    try {
      final resp = await ref.read(dioProvider).get('/athletes/${widget.athleteId}');
      if (!mounted) return;
      final data = resp.data is Map && resp.data['data'] is Map
          ? resp.data['data'] as Map<String, dynamic>
          : resp.data as Map<String, dynamic>;
      final shortlist = ref.read(scoutShortlistProvider).items;
      final already = shortlist.any((e) => e.athlete.id == widget.athleteId);
      setState(() {
        _athlete = data;
        _isLoading = false;
        _isShortlisted = already;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load athlete profile';
        _isLoading = false;
      });
    }
  }

  // ── helpers to safely read API fields ──
  String get _name => (_athlete!['user']?['name'] ?? _athlete!['full_name'] ?? 'Athlete').toString();
  String? get _photoUrl => (_athlete!['photo']?['url'] as String?) ?? _athlete!['photo_url'] as String?;
  bool get _isVerified => _athlete!['is_verified'] == true;
  String get _bio => (_athlete!['experience'] ?? _athlete!['bio'] ?? _athlete!['description'] ?? '').toString();
  List<dynamic> get _sports => (_athlete!['sports'] as List?) ?? const [];
  String get _primarySport => _sports.isNotEmpty ? ((_sports.first as Map)['name'] ?? '').toString() : '';
  String get _ageGroup {
    final ag = _athlete!['age_group'] ?? _athlete!['ageGroup'];
    if (ag is Map) return (ag['label'] ?? ag['name'] ?? '').toString();
    return '';
  }
  String get _skillLevel => (_athlete!['skill_level'] ?? '').toString();
  String get _gender => (_athlete!['gender'] ?? '').toString();
  String get _location {
    final city = _athlete!['city'];
    if (city is Map) {
      final name = (city['name'] ?? '').toString();
      final state = (city['state'] ?? '').toString();
      if (name.isEmpty) return '';
      return state.isNotEmpty ? '$name, $state' : name;
    }
    return (_athlete!['city_name'] ?? '').toString();
  }
  List<dynamic> get _achievements => (_athlete!['achievements'] as List?) ?? const [];
  List<dynamic> get _media {
    final m = _athlete!['media'] ?? _athlete!['media_items'] ?? _athlete!['media_gallery'];
    if (m is List) return m;
    return const [];
  }
  List<dynamic> get _tournamentHistory => (_athlete!['tournament_history'] as List?) ?? const [];
  List<dynamic> get _performanceStats => (_athlete!['performance_stats'] as List?) ?? const [];
  String? get _dob {
    final raw = _athlete!['date_of_birth']?.toString();
    if (raw == null || raw.isEmpty) return null;
    return raw.length >= 10 ? raw.substring(0, 10) : raw;
  }
  int get _connectionsCount {
    final v = _athlete!['connections_count'];
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Athlete Profile',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        centerTitle: false,
        leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
            onPressed: () => context.pop()),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
      ),
      body: _isLoading
          ? const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: CoachProfileViewSkeleton(),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.border),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _error = null;
                          });
                          _loadAthlete();
                        },
                        style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _athlete == null
                  ? const Center(child: Text('Athlete not found'))
                  : RefreshIndicator(
                      onRefresh: _loadAthlete,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildProfileHeader(),
                            _buildSectionDivider(),
                            _buildAboutSection(),
                            _buildSectionDivider(),
                            _buildSportsSection(),
                            _buildSectionDivider(),
                            _buildAchievementsSection(),
                            _buildSectionDivider(),
                            _buildTournamentHistorySection(),
                            _buildSectionDivider(),
                            _buildPerformanceStatsSection(),
                            _buildSectionDivider(),
                            _buildMediaGallerySection(),
                            _buildSectionDivider(),
                            _buildActionButtons(),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
    );
  }

  // ── sections ──

  Widget _buildSectionDivider() => Container(height: 8, color: AppColors.surface);

  Widget _buildProfileHeader() {
    final resolved = MediaUtils.resolveNullable(_photoUrl);
    final subtitle = [
      if (_primarySport.isNotEmpty) _primarySport,
      if (_ageGroup.isNotEmpty) _ageGroup,
    ].join(' · ');
    final metaLine = [
      if (_skillLevel.isNotEmpty) _skillLevel,
      if (_gender.isNotEmpty) _gender,
      if (_dob != null) 'DOB $_dob',
    ].join('  •  ');

    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [AppColors.primary, Color(0xFF0d47a1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: ClipOval(
              child: resolved != null
                  ? Image.network(resolved,
                      width: 96, height: 96, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(LucideIcons.user, size: 48, color: Colors.white))
                  : const Icon(LucideIcons.user, size: 48, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Flexible(
              child: Text(_name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ),
            if (_isVerified) ...[
              const SizedBox(width: 6),
              const Icon(LucideIcons.badgeCheck, color: AppColors.verifiedBadge, size: 20),
            ],
          ]),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          ],
          if (_location.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(LucideIcons.mapPin, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(_location, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ]),
          ],
          if (metaLine.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
              child: Text(metaLine, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.primary)),
            ),
          ],
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _buildHeaderStatItem('${_achievements.length}', 'Achievements'),
            const SizedBox(width: 32),
            _buildHeaderStatItem('$_connectionsCount', 'Connects'),
            const SizedBox(width: 32),
            _buildHeaderStatItem('${_sports.length}', 'Sports'),
          ]),
        ],
      ),
    );
  }

  Widget _buildHeaderStatItem(String value, String label) => Column(children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ]);

  Widget _buildAboutSection() {
    final hasBio = _bio.trim().isNotEmpty;
    return _buildSection(
      title: 'About',
      child: hasBio
          ? Text(_bio, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5))
          : const Text('No bio added yet', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
    );
  }

  Widget _buildSportsSection() {
    if (_sports.isEmpty) {
      return _buildSection(title: 'Sports Specialization', child: const Text('No sports listed', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)));
    }
    return _buildSection(
      title: 'Sports Specialization',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _sports.map((s) {
          final name = (s is Map ? s['name'] ?? '' : s).toString();
          if (name.isEmpty) return const SizedBox.shrink();
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15))),
            child: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAchievementsSection() {
    if (_achievements.isEmpty) {
      return _buildSection(
        title: 'Achievements',
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
          child: const Row(children: [
            Icon(LucideIcons.trophy, size: 20, color: AppColors.textSecondary),
            SizedBox(width: 10),
            Text('No achievements yet', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          ]),
        ),
      );
    }
    return _buildSection(
      title: 'Achievements',
      child: Column(
        children: _achievements.map((a) {
          if (a is! Map) return const SizedBox.shrink();
          final title = (a['title'] ?? a['text'] ?? a['description'] ?? 'Achievement').toString();
          final subtitle = (a['description'] != null && a['title'] != null) ? a['description'].toString() : '';
          final year = (a['year'] ?? '').toString();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: const Color(0xFFfef3c7), borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.center,
                child: const Icon(LucideIcons.award, size: 18, color: Color(0xFF92400e)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                if (subtitle.isNotEmpty) ...[const SizedBox(height: 2), Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))],
                if (year.isNotEmpty) ...[const SizedBox(height: 2), Text(year, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))],
              ])),
            ]),
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
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(children: [
              const Icon(LucideIcons.trophy, size: 40, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              const Text('No tournament history yet', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Text('Tournaments this athlete participates in will appear here',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.7))),
            ]),
          ),
        ),
      );
    }
    return _buildSection(
      title: 'Tournament History',
      child: Column(
        children: _tournamentHistory.map((t) {
          final m = t is Map<String, dynamic> ? t : Map<String, dynamic>.from(t as Map);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                  alignment: Alignment.center,
                  child: Text(m['icon'] ?? '🏆', style: const TextStyle(fontSize: 20))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text((m['name'] ?? '').toString(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text('${m['year'] ?? ''} • ${m['result'] ?? ''}'.trim(), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ])),
            ]),
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
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(children: [
              const Icon(LucideIcons.barChart3, size: 40, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              const Text('No stats available', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Text('Performance stats will appear here after tournaments',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.7))),
            ]),
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
          final m = stat is Map<String, dynamic> ? stat : Map<String, dynamic>.from(stat as Map);
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text((m['value'] ?? '0').toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
              Text((m['label'] ?? '').toString(), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ]),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMediaGallerySection() {
    final images = _media
        .whereType<Map>()
        .map((m) => MediaUtils.resolveNullable((m['url'] ?? m['path'] ?? '').toString()))
        .where((u) => u != null && u.isNotEmpty)
        .cast<String>()
        .toList();

    return _buildSection(
      title: 'Media Gallery',
      child: images.isEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(children: [
                  const Icon(LucideIcons.image, size: 40, color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  const Text('No media yet', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text('Photos and videos will appear here',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.7))),
                ]),
              ),
            )
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: images.length,
              itemBuilder: (context, index) {
                final isVideo = (_media[index] as Map)['media_type'] == 'video' || (_media[index] as Map)['type'] == 'video';
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(fit: StackFit.expand, children: [
                    Image.network(images[index],
                        fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(color: AppColors.surface, child: const Icon(LucideIcons.image, color: AppColors.textSecondary))),
                    if (isVideo) Container(color: Colors.black38, child: const Center(child: Icon(LucideIcons.play, color: Colors.white, size: 24))),
                  ]),
                );
              },
            ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isShortlisted
                  ? null
                  : () async {
                      final success = await ref.read(scoutShortlistProvider.notifier).addToShortlist(widget.athleteId);
                      if (!mounted) return;
                      final error = ref.read(scoutShortlistProvider).error;
                      if (success) {
                        if (!mounted) return;
                        setState(() => _isShortlisted = true);
                        if (!context.mounted) return;
                        SnackBarUtils.showSuccess(context, 'Added to shortlist');
                      } else if (error == 'Already shortlisted') {
                        if (!mounted) return;
                        setState(() => _isShortlisted = true);
                        if (!context.mounted) return;
                        SnackBarUtils.showError(context, 'Already shortlisted');
                      } else {
                        if (!context.mounted) return;
                        SnackBarUtils.showError(context, error ?? 'Failed to add to shortlist');
                      }
                    },
              icon: Icon(_isShortlisted ? LucideIcons.check : LucideIcons.star, size: 18),
              label: Text(_isShortlisted ? 'Shortlisted' : 'Shortlist'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _isShortlisted ? AppColors.textSecondary : AppColors.primary,
                side: BorderSide(color: _isShortlisted ? AppColors.border : AppColors.primary),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: _buildConnectButton()),
        ]),
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: () => context.push('/scout-shortlist'),
            icon: const Icon(LucideIcons.star, size: 14, color: AppColors.textSecondary),
            label: const Text('View My Shortlist', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
        ),
      ]),
    );
  }

  Widget _buildConnectButton() {
    String? status;
    for (final c in ref.watch(scoutConnectionProvider).connections) {
      final athleteId =
          c['athlete_profile_id']?.toString() ?? (c['athlete'] as Map<String, dynamic>?)?['id']?.toString();
      if (athleteId == widget.athleteId) {
        status = c['status']?.toString();
        break;
      }
    }
    if (status == 'accepted') {
      return FilledButton.icon(
        onPressed: () => context.push('/scout-connections'),
        icon: const Icon(LucideIcons.check, size: 18),
        label: const Text('Connected'),
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF065f46), minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      );
    }
    if (status == 'pending') {
      return OutlinedButton.icon(
        onPressed: () => context.push('/scout-connections'),
        icon: const Icon(LucideIcons.clock, size: 18),
        label: const Text('Request Sent'),
        style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF92400e), side: const BorderSide(color: Color(0xFF92400e)), minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      );
    }
    return FilledButton.icon(
      onPressed: () => context.push('/scout-connect/${widget.athleteId}'),
      icon: const Icon(LucideIcons.messageCircle, size: 18),
      label: const Text('Connect'),
      style: FilledButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
    );
  }

  Widget _buildSection({required String title, Widget? action, required Widget child}) {
    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          // ignore: use_null_aware_elements
          if (action != null) action,
        ]),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: child),
      ]),
    );
  }
}
