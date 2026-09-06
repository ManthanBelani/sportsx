import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/athlete_discovery_provider.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/scout_shortlist_provider.dart';
import 'package:sportx_app/features/talent_scout/presentation/widgets/athlete_avatar.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';

class TalentScoutAthleteDiscoveryScreen extends ConsumerStatefulWidget {
  const TalentScoutAthleteDiscoveryScreen({super.key});

  @override
  ConsumerState<TalentScoutAthleteDiscoveryScreen> createState() => _TalentScoutAthleteDiscoveryScreenState();
}

class _TalentScoutAthleteDiscoveryScreenState extends ConsumerState<TalentScoutAthleteDiscoveryScreen> {
  final _searchController = TextEditingController();
  String? _selectedSport;
  String? _selectedSkillLevel;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(athleteDiscoveryProvider.notifier).searchAthletes());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final filters = <String, dynamic>{};
    if (_searchController.text.isNotEmpty) filters['q'] = _searchController.text;
    if (_selectedSport != null) filters['sport_id'] = _selectedSport;
    if (_selectedSkillLevel != null) filters['skill_level'] = _selectedSkillLevel;
    ref.read(athleteDiscoveryProvider.notifier).searchAthletes(filters: filters);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(athleteDiscoveryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Discover Athletes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
            onPressed: () => context.pop()),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search athletes...',
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      suffixIcon: IconButton(
                        icon: const Icon(LucideIcons.slidersHorizontal, size: 18),
                        onPressed: () => setState(() => _showFilters = !_showFilters),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _applyFilters(),
                  ),
                ),
              ],
            ),
          ),

          // Filter Panel
          if (_showFilters)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedSport,
                      hint: const Text('Sport'),
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      items: const [
                        DropdownMenuItem(value: '1', child: Text('Cricket')),
                        DropdownMenuItem(value: '2', child: Text('Football')),
                        DropdownMenuItem(value: '3', child: Text('Kabaddi')),
                        DropdownMenuItem(value: '4', child: Text('Badminton')),
                        DropdownMenuItem(value: '5', child: Text('Tennis')),
                        DropdownMenuItem(value: '6', child: Text('Athletics')),
                        DropdownMenuItem(value: '7', child: Text('Hockey')),
                        DropdownMenuItem(value: '8', child: Text('Chess')),
                      ],
                      onChanged: (v) => setState(() => _selectedSport = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedSkillLevel,
                      hint: const Text('Skill Level'),
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      items: const [
                        DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                        DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
                        DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
                        DropdownMenuItem(value: 'competitive', child: Text('Competitive')),
                      ],
                      onChanged: (v) => setState(() => _selectedSkillLevel = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _applyFilters,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ),

          // Athlete List
          Expanded(
            child: state.isLoading && state.athletes.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.athletes.isEmpty
                    ? const Center(
                        child: Text('No athletes found',
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.athletes.length,
                        itemBuilder: (context, index) {
                          final athlete = state.athletes[index];
                          return _buildAthleteCard(athlete);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAthleteCard(dynamic athlete) {
    return GestureDetector(
      onTap: () => context.push('/scout-athlete/${athlete.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            AthleteAvatar(photoUrl: athlete.photoUrl, radius: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(athlete.fullName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (athlete.sports.isNotEmpty)
                        Text(athlete.sports.first,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      if (athlete.ageGroupName != null) ...[
                        const Text(' · ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text(athlete.ageGroupName!,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                  if (athlete.cityName != null)
                    Text(athlete.cityName!,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.star, size: 20),
                  color: AppColors.textSecondary,
                  onPressed: () async {
                    final success = await ref
                        .read(scoutShortlistProvider.notifier)
                        .addToShortlist(athlete.id);
                    if (mounted) {
                      final error = ref.read(scoutShortlistProvider).error;
                      if (success) {
                        SnackBarUtils.showSuccess(context, 'Added to shortlist');
                      } else if (error == 'Already shortlisted') {
                        SnackBarUtils.showError(context, 'Already shortlisted');
                      } else {
                        SnackBarUtils.showError(context, error ?? 'Failed to add to shortlist');
                      }
                    }
                  },
                ),
                Text('${athlete.achievementsCount}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
