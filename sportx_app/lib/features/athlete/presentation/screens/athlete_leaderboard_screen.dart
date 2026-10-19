import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/athlete/presentation/providers/leaderboard_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/providers/meta_provider.dart';
import 'package:sportx_app/theme/colors.dart';

/// Athlete Leaderboard Screen - shows rankings with period/category filters
class AthleteLeaderboardScreen extends ConsumerStatefulWidget {
  const AthleteLeaderboardScreen({super.key});

  static const routeName = '/athlete-leaderboard';

  @override
  ConsumerState<AthleteLeaderboardScreen> createState() => _AthleteLeaderboardScreenState();
}

class _AthleteLeaderboardScreenState extends ConsumerState<AthleteLeaderboardScreen> {
  LeaderboardPeriod _period = LeaderboardPeriod.weekly;
  LeaderboardCategory _category = LeaderboardCategory.xp;
  String? _selectedSportId;

  @override
  Widget build(BuildContext context) {
    final params = (period: _period, category: _category, sportId: _selectedSportId);
    final leaderboardAsync = ref.watch(leaderboardProvider(params));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: SportXTopBar(
        title: 'Leaderboard',
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.info, color: AppColors.textSecondary),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          _buildFilterBar(context),
          
          // Leaderboard Content
          Expanded(
            child: leaderboardAsync.when(
              loading: () => _buildLoadingState(),
              error: (e, _) => _buildErrorState(e),
              data: (state) => _buildLeaderboardContent(state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          // Period & Category Row
          Row(
            children: [
              Expanded(
                child: _FilterDropdown<LeaderboardPeriod>(
                  label: 'Period',
                  value: _period,
                  items: LeaderboardPeriod.values
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(_periodLabel(p), style: GoogleFonts.inter(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _period = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FilterDropdown<LeaderboardCategory>(
                  label: 'Category',
                  value: _category,
                  items: LeaderboardCategory.values
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(_categoryLabel(c), style: GoogleFonts.inter(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
              ),
            ],
          ),
          
          // Sport Filter
          const SizedBox(height: 12),
          Builder(builder: (_) {
            final sports = ref.watch(metaProvider).sports.where((s) => s.isActive).toList();
            if (sports.isEmpty) return const SizedBox.shrink();
            return _FilterDropdown<String?>(
              label: 'Sport',
              value: _selectedSportId,
              items: [
                const DropdownMenuItem(value: null, child: Text('All Sports')),
                ...sports.map((s) => DropdownMenuItem(
                      value: s.id.toString(),
                      child: Text(s.name, style: GoogleFonts.inter(fontSize: 13)),
                    )),
              ],
              onChanged: (v) => setState(() => _selectedSportId = v),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLeaderboardContent(LeaderboardState state) {
    if (state.entries.isEmpty && state.currentUserEntry == null) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(leaderboardProvider(
        (period: _period, category: _category, sportId: _selectedSportId),
      )),
      child: CustomScrollView(
        slivers: [
          // Current User Rank Card
          if (state.currentUserEntry != null)
            SliverToBoxAdapter(
              child: _CurrentUserRankCard(
                entry: state.currentUserEntry!,
                totalParticipants: state.totalParticipants,
                category: _category,
              ),
            ),
          
          // Podium (Top 3)
          if (state.entries.length >= 3)
            SliverToBoxAdapter(child: _PodiumView(entries: state.entries.take(3).toList())),
          
          // List (rank 4+)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entryIndex = index + (state.entries.length >= 3 ? 3 : 0);
                  if (entryIndex >= state.entries.length) return null;
                  final entry = state.entries[entryIndex];
                  return _LeaderboardRow(
                    entry: entry,
                    showRank: entryIndex + 1,
                    category: _category,
                  );
                },
                childCount: state.entries.length > 3 ? state.entries.length - 3 : 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SkeletonWidget.rectangular(height: 80, radius: 16),
        const SizedBox(height: 16),
        SkeletonWidget.rectangular(height: 140, radius: 16),
        const SizedBox(height: 16),
        ...List.generate(5, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SkeletonWidget.rectangular(height: 60, radius: 12),
            )),
      ],
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.alertCircle, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text('Could not load leaderboard', 
                style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 8),
            Text(ApiException.messageFor(error),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => ref.invalidate(leaderboardProvider(
                (period: _period, category: _category, sportId: _selectedSportId),
              )),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.trophy, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text('No rankings yet',
                style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 8),
            Text('Be the first to climb the leaderboard!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Leaderboard Info', style: GoogleFonts.sora(fontWeight: FontWeight.w700)),
        content: Text(
          'Rankings update in real-time based on your activity:\n\n'
          '• XP: Total experience points\n'
          '• Matches: Games played\n'
          '• Wins: Victories earned\n'
          '• Achievements: Medals & certificates\n'
          '• Connections: Network size\n\n'
          'Weekly resets every Monday. Season follows the sports calendar.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it')),
        ],
      ),
    );
  }

  String _periodLabel(LeaderboardPeriod p) {
    switch (p) {
      case LeaderboardPeriod.weekly: return 'This Week';
      case LeaderboardPeriod.monthly: return 'This Month';
      case LeaderboardPeriod.season: return 'Season';
      case LeaderboardPeriod.allTime: return 'All Time';
    }
  }

  String _categoryLabel(LeaderboardCategory c) {
    switch (c) {
      case LeaderboardCategory.xp: return 'XP Points';
      case LeaderboardCategory.matches: return 'Matches';
      case LeaderboardCategory.wins: return 'Wins';
      case LeaderboardCategory.achievements: return 'Achievements';
      case LeaderboardCategory.connections: return 'Connections';
    }
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        filled: true,
        fillColor: AppColors.surface,
      ),
      style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink),
      icon: const Icon(LucideIcons.chevronDown, size: 18, color: AppColors.textSecondary),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
    );
  }
}

class _CurrentUserRankCard extends StatelessWidget {
  final LeaderboardEntry entry;
  final int totalParticipants;
  final LeaderboardCategory category;
  const _CurrentUserRankCard({
    required this.entry,
    required this.totalParticipants,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final medalColor = _medalColorForRank(entry.rank);
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFCF0), Colors.white],
        ),
        border: Border.all(color: const Color(0xFFF0E3B2)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: SportXShadows.e1,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: medalColor.withValues(alpha: 0.16),
            ),
            alignment: Alignment.center,
            child: Text(
              '#${entry.rank}',
              style: GoogleFonts.sora(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: medalColor,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Your Rank',
                        style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    if (entry.isCurrentUser) ...[
                      const SizedBox(width: 8),
                      const Icon(LucideIcons.userCheck, size: 16, color: AppColors.success),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text('${_formatNumber(entry.score)} ${leaderboardCategoryUnit(category)}',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                if (entry.city != null && entry.city!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(LucideIcons.mapPin, size: 11, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(entry.city!,
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: medalColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              totalParticipants > 0
                  ? '#${entry.rank} of ${_formatNumber(totalParticipants)}'
                  : '#${entry.rank}',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: medalColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  Color _medalColorForRank(int rank) {
    if (rank == 1) return const Color(0xFFFFC107);
    if (rank == 2) return const Color(0xFFC0C6CF);
    if (rank == 3) return const Color(0xFFD8A15B);
    return AppColors.primary;
  }
}

class _PodiumView extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  const _PodiumView({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.length < 3) return const SizedBox.shrink();
    
    // entries are rank-ordered: index 0 is rank 1.
    final first = entries[0];
    final second = entries[1];
    final third = entries[2];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: SportXShadows.e1,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _PodiumPlace(entry: second, place: 2, height: 40),
          _PodiumPlace(entry: first, place: 1, height: 72),
          _PodiumPlace(entry: third, place: 3, height: 24),
        ],
      ),
    );
  }
}

class _PodiumPlace extends StatelessWidget {
  final LeaderboardEntry entry;
  final int place;
  final double height;

  const _PodiumPlace({required this.entry, required this.place, required this.height});

  @override
  Widget build(BuildContext context) {
    final colors = {
      1: const Color(0xFFFFC107),
      2: const Color(0xFFC0C6CF),
      3: const Color(0xFFD8A15B),
    };
    final color = colors[place] ?? AppColors.primary;

    return GestureDetector(
      onTap: () => context.push('/view-profile', extra: {'type': 'athlete', 'id': entry.userId}),
      child: SizedBox(
        width: 90,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 3),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: entry.avatarUrl != null && entry.avatarUrl!.isNotEmpty
                  ? ClipOval(child: Image.network(entry.avatarUrl!, fit: BoxFit.cover))
                  : Center(
                      child: Text(
                        entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
                        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            // Medal
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.16)),
              alignment: Alignment.center,
              child: Icon(
                place == 1 ? LucideIcons.trophy : LucideIcons.medal,
                size: 16,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            // Name
            Text(
              entry.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
            const SizedBox(height: 2),
            // Score
            Text(
              _formatScore(entry.score),
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color),
            ),
            // Platform
            Container(
              margin: const EdgeInsets.only(top: 8),
              height: height,
              width: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatScore(int score) {
    if (score >= 1000) return '${(score / 1000).toStringAsFixed(1)}K';
    return score.toString();
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final int showRank;
  final LeaderboardCategory category;
  const _LeaderboardRow({
    required this.entry,
    required this.showRank,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final isTop3 = showRank <= 3;
    final medalColor = isTop3
        ? (showRank == 1 ? const Color(0xFFFFC107) : showRank == 2 ? const Color(0xFFC0C6CF) : const Color(0xFFD8A15B))
        : AppColors.textTertiary;

    return GestureDetector(
      onTap: () => context.push('/view-profile', extra: {'type': 'athlete', 'id': entry.userId}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
          boxShadow: SportXShadows.e1,
        ),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 40,
              child: Center(
                child: Text(
                  '#$showRank',
                  style: GoogleFonts.sora(
                    fontSize: isTop3 ? 16 : 13,
                    fontWeight: FontWeight.w800,
                    color: medalColor,
                  ),
                ),
              ),
            ),
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFE9A8), Color(0xFFFFC107), Color(0xFFF5B400)],
                ),
              ),
              alignment: Alignment.center,
              child: entry.avatarUrl != null && entry.avatarUrl!.isNotEmpty
                  ? ClipOval(child: Image.network(entry.avatarUrl!, width: 40, height: 40, fit: BoxFit.cover))
                  : Text(
                      entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                        ),
                      ),
                      if (entry.isCurrentUser) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text('You',
                              style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.success)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (entry.sport.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.yellowTint,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(entry.sport,
                              style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primaryDarker)),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (entry.city != null && entry.city!.isNotEmpty) ...[
                        const Icon(LucideIcons.mapPin, size: 10, color: AppColors.textTertiary),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(entry.city!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.textSecondary)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Score
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatScore(entry.score),
                  style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
                Text(
                  leaderboardCategoryUnit(category),
                  style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatScore(int score) {
    if (score >= 1000) return '${(score / 1000).toStringAsFixed(1)}K';
    return score.toString();
  }
}