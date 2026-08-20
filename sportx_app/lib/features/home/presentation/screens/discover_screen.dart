import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sportx_app/features/search/presentation/providers/search_provider.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  int _selectedTab = 0;
  String? _selectedSport;
  String? _selectedState;
  String? _selectedAgeGroup;

  final List<String> _tabs = ['Athletes', 'Coaches', 'Sponsors'];

  final List<String> _sports = ['Cricket', 'Football', 'Badminton', 'Tennis', 'Hockey'];
  final List<String> _states = ['Maharashtra', 'Gujarat', 'Delhi', 'Karnataka', 'Tamil Nadu'];
  final List<String> _ageGroups = ['Under-14', 'Under-16', 'Under-19', 'Senior'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildTabPills(),
          _buildFilterChips(),
          Expanded(
            child: _selectedTab == 0
                ? _buildAthletesGrid()
                : _selectedTab == 1
                    ? _buildCoachesGrid()
                    : _buildSponsorsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => context.push('/universal-search'),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: AppColors.textTertiary),
            const SizedBox(width: 12),
            Text(
              'Search athletes, coaches...',
              style: TextStyle(color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPills() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTab == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_tabs[index]),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedTab = index);
              },
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFilterChips() {
    if (_selectedTab == 2) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip(
            label: _selectedSport ?? 'Sport',
            icon: Icons.sports,
            isSelected: _selectedSport != null,
            onTap: () => _showSportFilter(),
            onClear: _selectedSport != null ? () => setState(() => _selectedSport = null) : null,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: _selectedState ?? 'State',
            icon: Icons.location_on_outlined,
            isSelected: _selectedState != null,
            onTap: () => _showStateFilter(),
            onClear: _selectedState != null ? () => setState(() => _selectedState = null) : null,
          ),
          if (_selectedTab == 0) ...[
            const SizedBox(width: 8),
            _buildFilterChip(
              label: _selectedAgeGroup ?? 'Age Group',
              icon: Icons.cake_outlined,
              isSelected: _selectedAgeGroup != null,
              onTap: () => _showAgeFilter(),
              onClear: _selectedAgeGroup != null ? () => setState(() => _selectedAgeGroup = null) : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.infoLight : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAthletesGrid() {
    final athletes = ref.watch(athletesProvider);

    return athletes.when(
      data: (items) {
        final filtered = items.where((a) {
          final sport = a['sport'] as Map<String, dynamic>?;
          final city = a['city'] as Map<String, dynamic>?;
          if (_selectedSport != null && sport?['name'] != _selectedSport) return false;
          if (_selectedState != null && city?['name'] != _selectedState) return false;
          return true;
        }).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('No athletes found with selected filters'));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            return _buildAthleteCard(filtered[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildAthleteCard(dynamic athlete) {
    return InkWell(
      onTap: () => context.push('/view-profile', extra: {
        'type': 'athlete',
        'id': athlete.id.toString(),
      }),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                image: athlete.profilePhotoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(athlete.profilePhotoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: athlete.profilePhotoUrl == null
                  ? const Center(child: Icon(Icons.person, size: 40, color: AppColors.textTertiary))
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    athlete.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    athlete.sport?.name ?? 'Athlete',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          athlete.city?.name ?? 'India',
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachesGrid() {
    final coaches = ref.watch(coachesProvider);

    if (coaches.isLoading && coaches.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = coaches.items.where((c) {
      if (_selectedSport != null && c.sport?.name != _selectedSport) return false;
      if (_selectedState != null && c.city?.name != _selectedState) return false;
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('No coaches found with selected filters'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildCoachCard(filtered[index]);
      },
    );
  }

  Widget _buildCoachCard(dynamic coach) {
    return InkWell(
      onTap: () => context.push('/coach-profile-detail/${coach.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                image: coach.profilePhotoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(coach.profilePhotoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: coach.profilePhotoUrl == null
                  ? const Center(child: Icon(Icons.sports, size: 40, color: AppColors.textTertiary))
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coach.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    coach.specialization ?? 'Coach',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.work_outline, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${coach.experience ?? 0} years',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSponsorsGrid() {
    final sponsorships = ref.watch(sponsorshipsProvider);

    if (sponsorships.isLoading && sponsorships.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (sponsorships.items.isEmpty) {
      return const Center(child: Text('No sponsors found'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: sponsorships.items.length,
      itemBuilder: (context, index) {
        return _buildSponsorCard(sponsorships.items[index]);
      },
    );
  }

  Widget _buildSponsorCard(dynamic sponsor) {
    return InkWell(
      onTap: () => context.push('/sponsor-pitch/${sponsor.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: const Center(child: Icon(Icons.business_center, size: 40, color: AppColors.textTertiary)),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sponsor.title ?? 'Sponsorship',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sponsor.industry ?? 'Various',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.ctaLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      sponsor.budget ?? 'Contact for details',
                      style: TextStyle(
                        color: AppColors.ctaDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSportFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Select Sport', style: Theme.of(context).textTheme.titleMedium),
            ),
            ..._sports.map((sport) {
              return ListTile(
                title: Text(sport),
                trailing: _selectedSport == sport
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _selectedSport = sport);
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showStateFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Select State', style: Theme.of(context).textTheme.titleMedium),
            ),
            ..._states.map((state) {
              return ListTile(
                title: Text(state),
                trailing: _selectedState == state
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _selectedState = state);
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAgeFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Select Age Group', style: Theme.of(context).textTheme.titleMedium),
            ),
            ..._ageGroups.map((age) {
              return ListTile(
                title: Text(age),
                trailing: _selectedAgeGroup == age
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _selectedAgeGroup = age);
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
