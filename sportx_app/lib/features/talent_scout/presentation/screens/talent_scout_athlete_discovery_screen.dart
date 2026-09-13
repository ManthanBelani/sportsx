import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/athlete_discovery_provider.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/scout_shortlist_provider.dart';
import 'package:sportx_app/features/talent_scout/presentation/widgets/athlete_avatar.dart';
import 'package:sportx_app/shared/providers/meta_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';

class TalentScoutAthleteDiscoveryScreen extends ConsumerStatefulWidget {
  const TalentScoutAthleteDiscoveryScreen({super.key});

  @override
  ConsumerState<TalentScoutAthleteDiscoveryScreen> createState() =>
      _TalentScoutAthleteDiscoveryScreenState();
}

class _TalentScoutAthleteDiscoveryScreenState
    extends ConsumerState<TalentScoutAthleteDiscoveryScreen> {
  final _searchController = TextEditingController();
  int? _selectedSport;
  int? _selectedCity;
  int? _selectedAgeGroup;
  String? _selectedSkillLevel;
  bool _hasAchievements = false;
  bool _showFilters = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(athleteDiscoveryProvider.notifier).searchAthletes(),
    );
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref
            .read(athleteDiscoveryProvider.notifier)
            .loadMore(filters: _currentFilters());
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _currentFilters() {
    final m = <String, dynamic>{};
    final q = _searchController.text.trim();
    if (q.isNotEmpty) m['q'] = q;
    if (_selectedSport != null) m['sport_id'] = _selectedSport;
    if (_selectedCity != null) m['city_id'] = _selectedCity;
    if (_selectedAgeGroup != null) m['age_group_id'] = _selectedAgeGroup;
    if (_selectedSkillLevel != null) m['skill_level'] = _selectedSkillLevel;
    if (_hasAchievements) m['has_achievements'] = 1;
    return m;
  }

  void _applyFilters() {
    ref
        .read(athleteDiscoveryProvider.notifier)
        .searchAthletes(filters: _currentFilters());
  }

  void _clearFilters() {
    setState(() {
      _selectedSport = null;
      _selectedCity = null;
      _selectedAgeGroup = null;
      _selectedSkillLevel = null;
      _hasAchievements = false;
      _searchController.clear();
    });
    ref.read(athleteDiscoveryProvider.notifier).searchAthletes();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(athleteDiscoveryProvider);
    final meta = ref.watch(metaProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Discover Athletes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search athletes by name...',
                      prefixIcon: const Icon(
                        LucideIcons.search,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showFilters
                              ? LucideIcons.x
                              : LucideIcons.slidersHorizontal,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        onPressed: () =>
                            setState(() => _showFilters = !_showFilters),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                    onSubmitted: (_) => _applyFilters(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _applyFilters,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  child: const Icon(
                    LucideIcons.search,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Quick filter chips row (sport, age, city) per spec 5.3
          if (!_showFilters &&
              (meta.sports.isNotEmpty || meta.cities.isNotEmpty))
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _filterChip('All', _selectedSport == null, () {
                    setState(() => _selectedSport = null);
                    _applyFilters();
                  }),
                  const SizedBox(width: 8),
                  ...meta.sports
                      .take(6)
                      .map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _filterChip(
                            s.name,
                            _selectedSport == s.id,
                            () {
                              setState(() => _selectedSport = s.id);
                              _applyFilters();
                            },
                          ),
                        ),
                      ),
                ],
              ),
            ),

          // Advanced Filters Panel
          if (_showFilters)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Advanced Filters',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text(
                          'Clear all',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _selectedSport,
                          hint: const Text(
                            'Sport',
                            style: TextStyle(fontSize: 13),
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          items: meta.sports
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(
                                    s.name,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _selectedSport = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _selectedAgeGroup,
                          hint: const Text(
                            'Age Group',
                            style: TextStyle(fontSize: 13),
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          items: meta.ageGroups
                              .map(
                                (a) => DropdownMenuItem(
                                  value: a.id,
                                  child: Text(
                                    a.label,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedAgeGroup = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _selectedCity,
                          hint: const Text(
                            'City',
                            style: TextStyle(fontSize: 13),
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          items: meta.cities
                              .take(50)
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(
                                    c.name,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _selectedCity = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedSkillLevel,
                          hint: const Text(
                            'Skill Level',
                            style: TextStyle(fontSize: 13),
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'beginner',
                              child: Text(
                                'Beginner',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'intermediate',
                              child: Text(
                                'Intermediate',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'advanced',
                              child: Text(
                                'Advanced',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'competitive',
                              child: Text(
                                'Competitive',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedSkillLevel = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: _hasAchievements,
                        onChanged: (v) =>
                            setState(() => _hasAchievements = v ?? false),
                        activeColor: AppColors.primary,
                      ),
                      const Text(
                        'Has achievements',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: _applyFilters,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        child: const Text('Apply Filters'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Results count
          if (!state.isLoading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${state.athletes.length} athlete${state.athletes.length == 1 ? '' : 's'} found',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),

          // Athlete List
          Expanded(
            child: state.isLoading && state.athletes.isEmpty
                ? const GenericListSkeleton()
                : state.error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.error!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _applyFilters,
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : state.athletes.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.searchX,
                          size: 48,
                          color: AppColors.border,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No athletes found',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Try adjusting filters',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async => _applyFilters(),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount:
                          state.athletes.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.athletes.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        }
                        return _buildAthleteCard(state.athletes[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: selected ? Colors.white : AppColors.textSecondary,
        ),
      ),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      onSelected: (_) => onTap(),
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
          borderRadius: BorderRadius.circular(12),
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
                  Text(
                    athlete.fullName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (athlete.sports.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            athlete.sports.first,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (athlete.ageGroupName != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          athlete.ageGroupName!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (athlete.cityName != null) ...[
                        const Icon(
                          LucideIcons.mapPin,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          athlete.cityName!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (athlete.skillLevel != null) ...[
                        const Text(
                          ' • ',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          athlete.skillLevel!.toString(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
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
                        SnackBarUtils.showSuccess(
                          context,
                          'Added to shortlist',
                        );
                      } else if (error == 'Already shortlisted') {
                        SnackBarUtils.showError(context, 'Already shortlisted');
                      } else {
                        SnackBarUtils.showError(
                          context,
                          error ?? 'Failed to add to shortlist',
                        );
                      }
                    }
                  },
                ),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.award,
                      size: 12,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${athlete.achievementsCount}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
