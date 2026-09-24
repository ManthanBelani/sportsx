import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/models/models.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';

class TournamentCalendarScreen extends ConsumerStatefulWidget {
  const TournamentCalendarScreen({super.key});

  @override
  ConsumerState<TournamentCalendarScreen> createState() => _TournamentCalendarScreenState();
}

class _TournamentCalendarScreenState extends ConsumerState<TournamentCalendarScreen> {
  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDate;
  bool _showCalendar = true;

  final List<String> _dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  List<DateTime> _getDaysInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final startPadding = firstDay.weekday % 7;

    final days = <DateTime>[];

    for (int i = startPadding; i > 0; i--) {
      days.add(DateTime(month.year, month.month, 1).subtract(Duration(days: i)));
    }

    for (int i = 0; i < lastDay.day; i++) {
      days.add(DateTime(month.year, month.month, i + 1));
    }

    final remaining = 42 - days.length;
    for (int i = 1; i <= remaining; i++) {
      days.add(DateTime(month.year, month.month + 1, i));
    }

    return days;
  }

  List<Tournament> _getTournamentsForDate(List<Tournament> tournaments, DateTime date) {
    return tournaments.where((t) {
      if (t.startDate == null) return false;
      final tDate = t.startDate!;
      return tDate.year == date.year && tDate.month == date.month && tDate.day == date.day;
    }).toList();
  }

  List<Tournament> _getAllTournamentsForMonth(List<Tournament> tournaments, DateTime month) {
    return tournaments.where((t) {
      if (t.startDate == null) return false;
      return t.startDate!.year == month.year && t.startDate!.month == month.month;
    }).toList();
  }

  String _formatMonth(DateTime date) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tournamentsProvider);
    final tournaments = state.items;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: SportXTopBar(
        title: 'Tournaments',
        showBack: true,
        onBack: () => context.pop(),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
              boxShadow: SportXShadows.e1,
            ),
            child: Row(
              children: [
                _buildViewToggle('Calendar', _showCalendar, () => setState(() => _showCalendar = true)),
                _buildViewToggle('List', !_showCalendar, () => setState(() => _showCalendar = false)),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showCalendar) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _previousMonth,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: SportXShadows.e1,
                      ),
                      child: const Icon(LucideIcons.chevronLeft, size: 18, color: AppColors.textPrimary),
                    ),
                  ),
                  Text(
                    _formatMonth(_currentMonth),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  GestureDetector(
                    onTap: _nextMonth,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: SportXShadows.e1,
                      ),
                      child: const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: _dayLabels.map((label) => Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                    ),
                  ),
                )).toList(),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemCount: _getDaysInMonth(_currentMonth).length,
              itemBuilder: (context, index) {
                final date = _getDaysInMonth(_currentMonth)[index];
                final isCurrentMonth = date.month == _currentMonth.month;
                final isToday = date.year == DateTime.now().year &&
                               date.month == DateTime.now().month &&
                               date.day == DateTime.now().day;
                final hasEvent = _getTournamentsForDate(tournaments, date).isNotEmpty;
                final isSelected = _selectedDate != null &&
                                  date.year == _selectedDate!.year &&
                                  date.month == _selectedDate!.month &&
                                  date.day == _selectedDate!.day;

                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : hasEvent
                              ? AppColors.infoLight
                              : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isToday || hasEvent ? FontWeight.w600 : FontWeight.normal,
                              color: isCurrentMonth
                                  ? (isSelected ? AppColors.primary : AppColors.textPrimary)
                                   : AppColors.textSecondary.withValues(alpha: 0.4),
                            ),
                          ),
                          if (hasEvent)
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
          Expanded(
            child: _showCalendar && _selectedDate != null
                ? _buildEventsList(_getTournamentsForDate(tournaments, _selectedDate!))
                : _showCalendar
                    ? _buildEventsList(_getAllTournamentsForMonth(tournaments, _currentMonth))
                    : _buildListView(state),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.background : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildEventsList(List<Tournament> tournaments) {
    if (tournaments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.calendar, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              _selectedDate != null ? 'No tournaments on this date' : 'No tournaments this month',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: tournaments.length,
      itemBuilder: (context, i) {
        final tournament = tournaments[i];
        return _buildEventCard(tournament);
      },
    );
  }

  Widget _buildListView(DirectoryState<Tournament> state) {
    if (state.isLoading && state.items.isEmpty) {
      return const GenericListSkeleton();
    }

    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.trophy, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text(
              'No tournaments found',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(tournamentsProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: state.items.length,
        itemBuilder: (context, i) {
          return _buildEventCard(state.items[i]);
        },
      ),
    );
  }

  Widget _buildEventCard(Tournament tournament) {
    final prizeLabel = tournament.prizePool != null ? '₹${tournament.prizePool!.toStringAsFixed(0)}' : null;

    return GestureDetector(
      onTap: () => context.push('/tournament-detail/${tournament.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: SportXShadows.e1,
                  ),
                  child: const Icon(LucideIcons.trophy, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tournament.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(LucideIcons.mapPin, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              tournament.venue ?? tournament.city?.name ?? 'TBD',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
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
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.only(top: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    prizeLabel != null ? 'Prize: $prizeLabel' : 'View Details',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      tournament.status == 'open' ? 'Registration Open' : 'Coming Soon',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF15803D),
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
}