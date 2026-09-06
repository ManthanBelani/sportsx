import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/scout_shortlist_provider.dart';
import 'package:sportx_app/features/talent_scout/presentation/widgets/athlete_avatar.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';

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

  @override
  void initState() {
    super.initState();
    _loadAthlete();
  }

  Future<void> _loadAthlete() async {
    try {
      final resp = await ref.read(dioProvider).get('/athletes/${widget.athleteId}');
      if (!mounted) return;
      setState(() {
        _athlete = resp.data['data'];
        _isLoading = false;
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _athlete == null
              ? const Center(child: Text('Athlete not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Section
                      Center(
                        child: Column(
                          children: [
                            AthleteAvatar(
                              photoUrl: _athlete!['photo']?['url'] as String?,
                              radius: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _athlete!['user']?['name'] ?? 'Athlete',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            if (_athlete!['skill_level'] != null)
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _athlete!['skill_level'].toString().toUpperCase(),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Info Section
                      _buildSection('Information', [
                        if (_athlete!['age_group'] != null)
                          _buildInfoRow('Age Group', _athlete!['age_group']['name'] ?? ''),
                        if (_athlete!['city'] != null)
                          _buildInfoRow('City', _athlete!['city']['name'] ?? ''),
                        if (_athlete!['skill_level'] != null)
                          _buildInfoRow('Skill Level', _athlete!['skill_level']),
                      ]),

                      // Sports
                      if (_athlete!['sports'] != null && (_athlete!['sports'] as List).isNotEmpty)
                        _buildSection('Sports', [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (_athlete!['sports'] as List)
                                .map((s) => Chip(
                                      label: Text(s['name'] ?? ''),
                                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                      labelStyle: const TextStyle(fontSize: 12, color: AppColors.primary),
                                    ))
                                .toList(),
                          ),
                        ]),

                      // Achievements
                      if (_athlete!['achievements'] != null && (_athlete!['achievements'] as List).isNotEmpty)
                        _buildSection('Achievements', (_athlete!['achievements'] as List)
                            .map((a) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      const Icon(LucideIcons.award, size: 16, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(a['title'] ?? a['description'] ?? '',
                                            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList()),

                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final success = await ref
                                    .read(scoutShortlistProvider.notifier)
                                    .addToShortlist(widget.athleteId);
                                if (!mounted) return;
                                final error = ref.read(scoutShortlistProvider).error;
                                if (success) {
                                  SnackBarUtils.showSuccess(context, 'Added to shortlist');
                                } else if (error == 'Already shortlisted') {
                                  SnackBarUtils.showError(context, 'Already shortlisted');
                                } else {
                                  SnackBarUtils.showError(context, error ?? 'Failed to add to shortlist');
                                }
                              },
                              icon: const Icon(LucideIcons.star, size: 18),
                              label: const Text('Shortlist'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
          Text('$label: ', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
