import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/date_format_utils.dart';
import 'package:sportx_app/features/search/presentation/providers/search_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';

class UniversalSearchScreen extends ConsumerStatefulWidget {
  const UniversalSearchScreen({super.key});

  @override
  ConsumerState<UniversalSearchScreen> createState() => _UniversalSearchScreenState();
}

class _UniversalSearchScreenState extends ConsumerState<UniversalSearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    Future.microtask(() => ref.read(searchProvider.notifier).loadRecentSearches());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String value) {
    if (value.trim().isNotEmpty) {
      ref.read(searchProvider.notifier).search(value.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final trendingAsync = ref.watch(trendingSearchesProvider);
    final trendingSearches = trendingAsync.valueOrNull ?? ['Cricket', 'Football', 'Badminton', 'Tennis', 'IPL Trials', 'State Championship', 'Ahmedabad', 'Mumbai'];
    final hasResults = searchState.results != null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(hasResults),
            if (hasResults) _buildCategoryTabs(searchState),
            Expanded(
              child: _buildBody(searchState, trendingSearches),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool hasResults) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary, size: 24),
            ),
          ),
          if (hasResults) ...[
            Expanded(
              child: Text(
                _searchController.text.trim().isEmpty ? 'Results' : '"${_searchController.text.trim()}"',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/search-filter'),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Icon(LucideIcons.slidersHorizontal, color: AppColors.textSecondary, size: 18),
              ),
            ),
          ] else ...[
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 14, right: 8),
                      child: Icon(LucideIcons.search, color: AppColors.textSecondary, size: 18),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Search academies, coaches, trials...',
                          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        textInputAction: TextInputAction.search,
                        onSubmitted: _onSearchSubmitted,
                        onChanged: (val) => setState(() {}),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {});
                          _focusNode.requestFocus();
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(right: 14, left: 8),
                          child: Icon(LucideIcons.x, color: AppColors.textSecondary, size: 18),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(SearchState searchState, List<String> trendingSearches) {
    if (searchState.results == null && searchState.query.isEmpty) {
      return _buildSuggestions(trendingSearches, searchState);
    } else if (searchState.isLoading && searchState.results == null) {
      return const GenericListSkeleton();
    } else if (searchState.results != null) {
      return _buildCategoryResults(searchState.category, searchState.results, searchState);
    } else if (searchState.query.isNotEmpty && !searchState.isLoading) {
      return const Center(
        child: Text('No results found', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSuggestions(List<String> trendingSearches, SearchState searchState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (searchState.recentSearches.isNotEmpty) ...[
            Text('Recent Searches', style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 12),
            ...searchState.recentSearches.map((search) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = search;
                  _onSearchSubmitted(search);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.clock, color: AppColors.textSecondary, size: 16),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(search, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                      ),
                      GestureDetector(
                        onTap: () {
                          ref.read(searchProvider.notifier).removeRecentSearch(search);
                        },
                        child: const Icon(LucideIcons.x, color: AppColors.textSecondary, size: 14),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
          ],

          Text('Trending', style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: trendingSearches.map((term) => _buildTrendingChip(term, _iconForTrending(term))).toList(),
          ),

          const SizedBox(height: 24),
          Text('Quick Links', style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _buildQuickLink('Academies', LucideIcons.building2, '/academies'),
              _buildQuickLink('Coaches', LucideIcons.user, '/coaches'),
              _buildQuickLink('Trials', LucideIcons.circleDot, '/trials'),
              _buildQuickLink('Tournaments', LucideIcons.trophy, '/tournaments'),
              _buildQuickLink('Tournament Calendar', LucideIcons.calendar, '/tournament-calendar'),
              _buildQuickLink('Scholarships', LucideIcons.graduationCap, '/scholarships'),
              _buildQuickLink('Sponsorships', LucideIcons.star, '/sponsorships'),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconForTrending(String term) {
    final t = term.toLowerCase();
    if (t.contains('cricket')) return LucideIcons.circleDot;
    if (t.contains('football')) return LucideIcons.goal;
    if (t.contains('badminton')) return LucideIcons.venetianMask;
    if (t.contains('athletic')) return LucideIcons.footprints;
    if (t.contains('swim')) return LucideIcons.waves;
    if (t.contains('tennis')) return LucideIcons.circle;
    if (t.contains('trial')) return LucideIcons.clipboardList;
    if (t.contains('championship')) return LucideIcons.trophy;
    return LucideIcons.search;
  }

  Widget _buildTrendingChip(String label, IconData icon) {
    return SportXChip(
      label: label,
      icon: icon,
      onTap: () {
        _searchController.text = label;
        _onSearchSubmitted(label);
      },
    );
  }

  Widget _buildQuickLink(String label, IconData icon, String route) {
    return QuickTile(
      label: label,
      icon: icon,
      tintBg: AppColors.yellowTint,
      tintFg: AppColors.primaryDarker,
      onTap: () => context.push(route),
    );
  }

  Widget _buildCategoryTabs(SearchState searchState) {
    return Container(
      height: 46,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: SearchCategory.values.map((category) {
          if (category == SearchCategory.all) return const SizedBox.shrink(); // Hide 'All' tab to match design
          
          final isSelected = searchState.category == category;
          final count = _getCategoryCount(category, searchState.results);
          
          return GestureDetector(
            onTap: () => ref.read(searchProvider.notifier).setCategory(category),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: isSelected ? AppColors.primary : Colors.transparent, width: 2)),
              ),
              child: Row(
                children: [
                  Text(
                    _getCategoryLabel(category),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.yellowTint : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryResults(
    SearchCategory category,
    dynamic results,
    SearchState searchState,
  ) {
    List<Map<String, dynamic>> items;

    switch (category) {
      case SearchCategory.coaches:
        items = results.coaches;
        break;
      case SearchCategory.academies:
        items = results.academies;
        break;
      case SearchCategory.trials:
        items = results.trials;
        break;
      case SearchCategory.tournaments:
        items = results.tournaments;
        break;
      case SearchCategory.scholarships:
        items = results.scholarships;
        break;
      case SearchCategory.sponsors:
        items = results.sponsors;
        break;
      case SearchCategory.sportsVenues:
        items = results.sportsVenues;
        break;
      case SearchCategory.all:
        items = [
          ...results.coaches,
          ...results.academies,
          ...results.trials,
          ...results.tournaments,
          ...results.scholarships,
          ...results.sponsors,
          ...results.sportsVenues,
        ];
        break;
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.search, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No ${_getCategoryLabel(category).toLowerCase()} found',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: items.length + (searchState.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0 && category != SearchCategory.all) {
          // Result count header
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('${items.length} ${_getCategoryLabel(category).toLowerCase()} found', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          );
        }
        
        final itemIndex = index - (category != SearchCategory.all ? 1 : 0);
        if (itemIndex >= items.length) {
          if (searchState.isLoading) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return const SizedBox.shrink();
        }
        
        return _buildResultCard(items[itemIndex]);
      },
    );
  }

  Widget _buildResultCard(Map<String, dynamic> item) {
    final type = item['type'] as String? ?? '';
    final sport = item['sport'] is Map ? item['sport']['name'] as String? : null;
    final city = item['city'] is Map ? item['city']['name'] as String? : null;

    final title = (item['name'] ?? item['full_name'] ?? item['title'] ?? 'Unknown').toString();
    final subtitle = [sport, city, item['venue'] ?? item['address']]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .take(2)
        .join(' · ');

    // Real meta per item type — no hardcoded placeholders.
    String? meta;
    switch (type) {
      case 'trial':
        final dt = item['event_datetime']?.toString();
        if (dt != null) meta = 'Trial: ${DateFormatUtils.formatShortDate(dt)}';
        meta ??= item['entry_fee'] != null ? 'Fee: ${item['entry_fee']}' : null;
        break;
      case 'tournament':
        final dt = item['start_date']?.toString();
        if (dt != null) meta = 'Starts: ${DateFormatUtils.formatShortDate(dt)}';
        meta ??= item['prize_pool'] != null ? 'Prize: ₹${item['prize_pool']}' : null;
        break;
      case 'scholarship':
        final amount = item['amount'];
        if (amount is num) {
          meta = '₹${amount.toStringAsFixed(0)}';
        } else if (amount != null) {
          meta = '₹$amount';
        }
        meta ??= item['deadline']?.toString();
        break;
      case 'sponsorship':
        meta = item['deadline']?.toString();
        break;
      case 'academy':
        meta = item['fee_range'] as String?;
        break;
      case 'coach':
        meta = item['fee_structure'] as String?;
        break;
      case 'sports_venue':
        meta = item['pricing'] as String?;
        break;
    }

    return GestureDetector(
      onTap: () => _navigateToDetail(item),
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(_getIconForType(type), color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.sora(
                          fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                  if (meta != null && meta.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(meta, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(Map<String, dynamic> item) {
    final type = item['type'] as String? ?? '';
    final id = item['id']?.toString() ?? '';

    switch (type) {
      case 'coach':
        context.push('/coach-detail/$id');
        break;
      case 'academy':
        context.push('/academy-detail/$id');
        break;
      case 'trial':
        context.push('/trial-detail/$id');
        break;
      case 'tournament':
        context.push('/tournament-detail/$id');
        break;
      case 'scholarship':
        context.push('/scholarship-detail/$id');
        break;
      case 'sponsorship':
        context.push('/sponsorship-detail/$id');
        break;
      case 'sports_venue':
        context.push('/sports-venues');
        break;
    }
  }

  String _getCategoryLabel(SearchCategory category) {
    switch (category) {
      case SearchCategory.all: return 'All';
      case SearchCategory.coaches: return 'Coaches';
      case SearchCategory.academies: return 'Academies';
      case SearchCategory.trials: return 'Trials';
      case SearchCategory.tournaments: return 'Tournaments';
      case SearchCategory.scholarships: return 'Scholarships';
      case SearchCategory.sponsors: return 'Sponsors';
      case SearchCategory.sportsVenues: return 'Venues';
    }
  }

  int _getCategoryCount(SearchCategory category, dynamic results) {
    if (results == null) return 0;
    switch (category) {
      case SearchCategory.all: return results.totalCount;
      case SearchCategory.coaches: return results.coaches.length;
      case SearchCategory.academies: return results.academies.length;
      case SearchCategory.trials: return results.trials.length;
      case SearchCategory.tournaments: return results.tournaments.length;
      case SearchCategory.scholarships: return results.scholarships.length;
      case SearchCategory.sponsors: return results.sponsors.length;
      case SearchCategory.sportsVenues: return results.sportsVenues.length;
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'coach': return LucideIcons.user;
      case 'academy': return LucideIcons.building2;
      case 'trial': return LucideIcons.circleDot;
      case 'tournament': return LucideIcons.trophy;
      case 'scholarship': return LucideIcons.graduationCap;
      case 'sponsorship': return LucideIcons.briefcase;
      case 'sports_venue': return LucideIcons.mapPin;
      default: return LucideIcons.search;
    }
  }
}
