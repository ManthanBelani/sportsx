import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/scout_shortlist_provider.dart';
import 'package:sportx_app/features/talent_scout/presentation/widgets/athlete_avatar.dart';
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
  }

  Future<void> _loadAthlete() async {
    try {
      final resp = await ref.read(dioProvider).get('/athletes/${widget.athleteId}');
      if (!mounted) return;
      final data = resp.data is Map && resp.data['data'] is Map ? resp.data['data'] as Map<String, dynamic> : resp.data as Map<String, dynamic>;
      // Check shortlist status
      final shortlist = ref.read(scoutShortlistProvider).items;
      final already = shortlist.any((e) => e.athlete.id == widget.athleteId);
      setState(() {
        _athlete = data;
        _isLoading = false;
        _isShortlisted = already;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load athlete profile';
        _isLoading = false;
      });
    }
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
        leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
            onPressed: () => context.pop()),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
      ),
      body: _isLoading
          ? const GenericDetailSkeleton()
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
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Section
                      Center(
                        child: Column(
                          children: [
                            AthleteAvatar(
                              photoUrl: _athlete!['photo']?['url'] as String? ?? _athlete!['photo_url'] as String?,
                              radius: 52,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _athlete!['user']?['name'] ?? _athlete!['full_name'] ?? 'Athlete',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 6),
                            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              if (_athlete!['skill_level'] != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _athlete!['skill_level'].toString().toUpperCase(),
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.5),
                                  ),
                                ),
                              if (_athlete!['connections_count'] != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                                  child: Row(children: [
                                    const Icon(LucideIcons.users, size: 12, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text('${_athlete!['connections_count']} connections', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  ]),
                                ),
                              ],
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Info Section
                      _buildSection('Information', [
                        if (_athlete!['age_group'] != null) _buildInfoRow('Age Group', _athlete!['age_group']['name'] ?? ''),
                        if (_athlete!['city'] != null) _buildInfoRow('City', '${_athlete!['city']['name'] ?? ''}${_athlete!['city']['state'] != null ? ', ${_athlete!['city']['state']}' : ''}'),
                        if (_athlete!['skill_level'] != null) _buildInfoRow('Skill Level', _athlete!['skill_level'].toString()),
                        if (_athlete!['gender'] != null) _buildInfoRow('Gender', _athlete!['gender'].toString()),
                        if (_athlete!['date_of_birth'] != null) _buildInfoRow('DOB', _athlete!['date_of_birth'].toString().substring(0, 10)),
                      ]),

                      // Sports History — timeline per spec
                      if (_athlete!['sports'] != null && (_athlete!['sports'] as List).isNotEmpty)
                        _buildSection('Sports History', [
                          ...(_athlete!['sports'] as List).asMap().entries.map((entry) {
                            final s = entry.value as Map;
                            final isLast = entry.key == (_athlete!['sports'] as List).length - 1;
                            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Column(children: [
                                Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                                if (!isLast) Container(width: 2, height: 24, color: AppColors.border),
                              ]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(s['name'] ?? 'Sport', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                    const SizedBox(height: 2),
                                    Text('Active • ${_athlete!['skill_level'] ?? '—'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ]),
                                ),
                              ),
                            ]);
                          }),
                        ]),

                      // Sports chips fallback
                      if (_athlete!['sports'] != null && (_athlete!['sports'] as List).isNotEmpty)
                        _buildSection('Sports Specialization', [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (_athlete!['sports'] as List)
                                .map((s) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primary.withValues(alpha: 0.15))),
                                      child: Text(s['name'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                    ))
                                .toList(),
                          ),
                        ]),

                      // Achievements
                      _buildSection('Achievements', () {
                        final ach = _athlete!['achievements'] as List?;
                        if (ach == null || ach.isEmpty) {
                          return [const Text('No achievements yet', style: TextStyle(fontSize: 13, color: AppColors.textSecondary))];
                        }
                        return ach
                            .map((a) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFFfef3c7), borderRadius: BorderRadius.circular(6)), child: const Icon(LucideIcons.award, size: 14, color: Color(0xFF92400e))),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text(a['title'] ?? a['description'] ?? 'Achievement', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                          if (a['description'] != null && a['title'] != null) Text(a['description'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                        ]),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList();
                      }()),

                      // Media Gallery — per spec TS4
                      _buildSection('Media Gallery', () {
                        final media = (_athlete!['media'] ?? _athlete!['media_items'] ?? _athlete!['media_gallery']) as List?;
                        if (media == null || media.isEmpty) {
                          return [const Text('No media yet', style: TextStyle(fontSize: 13, color: AppColors.textSecondary))];
                        }
                        return [
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
                            itemCount: media.length.clamp(0, 9),
                            itemBuilder: (ctx, i) {
                              final m = media[i] as Map;
                              final url = m['url'] ?? m['path'] ?? '';
                              final isVideo = (m['media_type'] ?? m['type']) == 'video';
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Stack(fit: StackFit.expand, children: [
                                  if (url.toString().isNotEmpty)
                                    Image.network(url.toString(), fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(color: AppColors.surface, child: const Icon(LucideIcons.image, color: AppColors.textSecondary)))
                                  else
                                    Container(color: AppColors.surface, child: const Icon(LucideIcons.image, color: AppColors.textSecondary)),
                                  if (isVideo) const Center(child: Icon(LucideIcons.play, color: Colors.white, size: 24)),
                                ]),
                              );
                            },
                          ),
                        ];
                      }()),

                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
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
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => context.push('/scout-connect/${widget.athleteId}'),
                              icon: const Icon(LucideIcons.messageCircle, size: 18),
                              label: const Text('Connect'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton.icon(
                          onPressed: () => context.push('/scout-shortlist'),
                          icon: const Icon(LucideIcons.star, size: 14, color: AppColors.textSecondary),
                          label: const Text('View My Shortlist', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}