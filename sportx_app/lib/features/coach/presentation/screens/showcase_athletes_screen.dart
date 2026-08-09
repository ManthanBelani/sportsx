import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sportx_app/features/coach/presentation/providers/coach_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class ShowcaseAthletesScreen extends ConsumerStatefulWidget {
  const ShowcaseAthletesScreen({super.key});

  @override
  ConsumerState<ShowcaseAthletesScreen> createState() => _ShowcaseAthletesScreenState();
}

class _ShowcaseAthletesScreenState extends ConsumerState<ShowcaseAthletesScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _selectedAthletes = [];
  bool _isSearching = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSelectedAthletes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadSelectedAthletes() {
    final coachState = ref.read(coachProvider);
    setState(() {
      _selectedAthletes = List<Map<String, dynamic>>.from(coachState.showcaseAthletes);
    });
  }

  Future<void> _searchAthletes(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await ref.read(coachProvider.notifier).searchAthletes(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  void _toggleAthleteSelection(Map<String, dynamic> athlete) {
    setState(() {
      final isSelected = _selectedAthletes.any((a) => a['id'] == athlete['id']);
      if (isSelected) {
        _selectedAthletes.removeWhere((a) => a['id'] == athlete['id']);
      } else {
        _selectedAthletes.add(athlete);
      }
    });
  }

  bool _isAthleteSelected(Map<String, dynamic> athlete) {
    return _selectedAthletes.any((a) => a['id'] == athlete['id']);
  }

  Future<void> _saveShowcase() async {
    setState(() => _isSaving = true);

    try {
      await ref.read(coachProvider.notifier).updateShowcaseAthletes(_selectedAthletes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Showcase athletes updated!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update showcase: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Showcase Athletes'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveShowcase,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _searchAthletes,
              decoration: InputDecoration(
                hintText: 'Search athletes to showcase...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _searchAthletes('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_selectedAthletes.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Selected Athletes (${_selectedAthletes.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _selectedAthletes.length,
                itemBuilder: (context, index) {
                  final athlete = _selectedAthletes[index];
                  return _buildSelectedAthleteChip(athlete);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_isSearching)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final athlete = _searchResults[index];
                  final isSelected = _isAthleteSelected(athlete);
                  return _buildAthleteTile(athlete, isSelected);
                },
              ),
            )
          else if (_searchController.text.isNotEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: AppColors.textTertiary),
                    const SizedBox(height: 16),
                    Text(
                      'No athletes found',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: AppColors.textTertiary),
                    const SizedBox(height: 16),
                    Text(
                      'Search for athletes to showcase',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to select or deselect athletes',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedAthleteChip(Map<String, dynamic> athlete) {
    return GestureDetector(
      onTap: () => _toggleAthleteSelection(athlete),
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: athlete['profile_photo_url'] != null
                      ? NetworkImage(athlete['profile_photo_url'])
                      : null,
                  backgroundColor: AppColors.surface,
                  child: athlete['profile_photo_url'] == null
                      ? const Icon(Icons.person, color: AppColors.textTertiary)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              athlete['name'] ?? 'Athlete',
              style: const TextStyle(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAthleteTile(Map<String, dynamic> athlete, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.successLight : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.success : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: athlete['profile_photo_url'] != null
              ? NetworkImage(athlete['profile_photo_url'])
              : null,
          backgroundColor: AppColors.surface,
          child: athlete['profile_photo_url'] == null
              ? const Icon(Icons.person, color: AppColors.textTertiary)
              : null,
        ),
        title: Text(
          athlete['name'] ?? 'Athlete',
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          athlete['sport'] ?? '',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Icon(
          isSelected ? Icons.check_circle : Icons.add_circle_outline,
          color: isSelected ? AppColors.success : AppColors.textTertiary,
        ),
        onTap: () => _toggleAthleteSelection(athlete),
      ),
    );
  }
}
