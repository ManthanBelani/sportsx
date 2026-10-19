import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sportx_app/features/coach/presentation/providers/coach_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';

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
  String? _searchError;
  Timer? _debounce;
  int _searchSeq = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Called whenever the coach profile finishes loading, so the selection stays
/// in sync with the server rather than being snapshotted before any fetch runs.
void _syncSelectedFromProvider(List<Map<String, dynamic>> showcase) {
  if (!mounted || _isSaving) return;
  setState(() {
    _selectedAthletes = showcase.map((e) => Map<String, dynamic>.from(e)).toList();
  });
  }

  /// Debounced so we don't fire an API call on every keystroke.
  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _searchError = null;
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 350), () => _runSearch(query));
  }

  Future<void> _runSearch(String query) async {
    final seq = ++_searchSeq;
    final result = await ref.read(coachProvider.notifier).searchAthletes(query);
    // Ignore if the user typed again or left the screen while this was in flight.
    if (!mounted || seq != _searchSeq) return;

    setState(() {
      _searchResults = result.rows;
      _searchError = result.error;
      _isSearching = false;
    });
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
        SnackBarUtils.showSuccess(context, 'Showcase athletes updated!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, e, 'Failed to update showcase. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coachState = ref.watch(coachProvider);
    // Keep the selection in sync once the profile arrives (or is refetched).
    if (!coachState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncSelectedFromProvider(coachState.showcaseAthletes);
      });
    }
    if (coachState.isLoading && _selectedAthletes.isEmpty && _searchResults.isEmpty && _searchController.text.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(title: const Text('Showcase Athletes'), backgroundColor: AppColors.surface),
        body: const ShowcaseSkeleton(),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Showcase Athletes'),
        backgroundColor: AppColors.surface,
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
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search athletes to showcase...',
                prefixIcon: const Icon(LucideIcons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
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
            const Expanded(child: ShowcaseSkeleton())
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
          else if (_searchError != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.alertCircle, size: 40, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text(
                        _searchError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.error, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_searchController.text.isNotEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.searchX, size: 64, color: AppColors.textTertiary),
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
                    Icon(LucideIcons.users, size: 64, color: AppColors.textTertiary),
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
                  backgroundColor: Colors.white,
                  child: athlete['profile_photo_url'] == null
                      ? const Icon(LucideIcons.user, color: AppColors.textTertiary)
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
                    child: const Icon(LucideIcons.check, color: Colors.white, size: 14),
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
        borderRadius: BorderRadius.circular(16),
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
          backgroundColor: Colors.white,
          child: athlete['profile_photo_url'] == null
              ? const Icon(LucideIcons.user, color: AppColors.textTertiary)
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
          isSelected ? LucideIcons.circleCheck : LucideIcons.circlePlus,
          color: isSelected ? AppColors.success : AppColors.textTertiary,
        ),
        onTap: () => _toggleAthleteSelection(athlete),
      ),
    );
  }
}
