import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/search/presentation/providers/search_provider.dart';
import 'package:sportx_app/shared/providers/meta_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class SearchFilterScreen extends ConsumerStatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  ConsumerState<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends ConsumerState<SearchFilterScreen> {
  late SearchFilters _currentFilters;

  String _selectedGender = 'all';

  RangeValues _feeRange = const RangeValues(0, 30000);
  bool _feeEnabled = false;

  @override
  void initState() {
    super.initState();
    _currentFilters = ref.read(searchProvider).filters;
    _selectedGender = _currentFilters.gender;
    if (_currentFilters.feeMin != null || _currentFilters.feeMax != null) {
      _feeEnabled = true;
      _feeRange = RangeValues(
        _currentFilters.feeMin ?? 0,
        _currentFilters.feeMax ?? 30000,
      );
    }
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom
        ? (_currentFilters.dateFrom ?? DateTime.now())
        : (_currentFilters.dateTo ?? _currentFilters.dateFrom ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      helpText: isFrom ? 'Select from date' : 'Select to date',
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _currentFilters = _currentFilters.copyWith(dateFrom: picked, clearDateFrom: false);
        // Keep the range consistent.
        if (_currentFilters.dateTo != null && _currentFilters.dateTo!.isBefore(picked)) {
          _currentFilters = _currentFilters.copyWith(dateTo: picked, clearDateTo: false);
        }
      } else {
        _currentFilters = _currentFilters.copyWith(dateTo: picked, clearDateTo: false);
        if (_currentFilters.dateFrom != null && _currentFilters.dateFrom!.isAfter(picked)) {
          _currentFilters = _currentFilters.copyWith(dateFrom: picked, clearDateFrom: false);
        }
      }
    });
  }

  Future<void> _pickCity() async {
    final cities = ref.read(metaProvider).cities;
    if (cities.isEmpty) return;
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: ListView.builder(
          itemCount: cities.length,
          itemBuilder: (context, index) {
            final city = cities[index];
            return ListTile(
              title: Text(city.name, style: const TextStyle(color: AppColors.textPrimary)),
              subtitle: Text(city.state, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              onTap: () => Navigator.pop(context, {'id': city.id, 'name': city.name}),
            );
          },
        ),
      ),
    );
    if (selected == null) return;
    setState(() {
      _currentFilters = _currentFilters.copyWith(cityId: selected['id'] as int, clearCityId: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final meta = ref.watch(metaProvider);
    final sports = meta.sports;
    final cityName = _currentFilters.cityId != null ? _cityNameById(meta, _currentFilters.cityId!) : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.x, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      title: 'Sport',
                      child: sports.isEmpty
                          ? const Text('Loading sports…', style: TextStyle(fontSize: 13, color: AppColors.textSecondary))
                          : _buildChips(
                              options: ['All Sports', ...sports.map((s) => s.name)],
                              selected: [
                                if (_currentFilters.sportId != null)
                                  _sportNameById(sports, _currentFilters.sportId!),
                              ].whereType<String>().toList(),
                              onSelect: (sport) {
                                setState(() {
                                  if (sport == 'All Sports') {
                                    _currentFilters = _currentFilters.copyWith(clearSportId: true, sports: []);
                                  } else {
                                    final match = sports.firstWhere((s) => s.name == sport);
                                    _currentFilters = _currentFilters.copyWith(sportId: match.id, sports: [sport]);
                                  }
                                });
                              },
                            ),
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Location',
                      child: _buildPickerField(
                        label: 'City',
                        value: cityName,
                        hint: 'Select city',
                        icon: LucideIcons.mapPin,
                        onTap: _pickCity,
                        onClear: _currentFilters.cityId == null
                            ? null
                            : () => setState(() {
                                  _currentFilters = _currentFilters.copyWith(clearCityId: true, locations: []);
                                }),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Fee Range (per month)',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text('Enable fee filter', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              ),
                              Switch(
                                value: _feeEnabled,
                                activeColor: AppColors.primary,
                                onChanged: (v) => setState(() {
                                  _feeEnabled = v;
                                  if (!v) {
                                    _currentFilters = _currentFilters.copyWith(clearFeeMin: true, clearFeeMax: true);
                                  } else {
                                    _currentFilters = _currentFilters.copyWith(
                                      feeMin: _feeRange.start,
                                      feeMax: _feeRange.end,
                                    );
                                  }
                                }),
                              ),
                            ],
                          ),
                          if (_feeEnabled) ...[
                            SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: AppColors.primary,
                                inactiveTrackColor: AppColors.border,
                                thumbColor: AppColors.primary,
                                overlayColor: AppColors.primary.withOpacity(0.2),
                                trackHeight: 4,
                              ),
                              child: RangeSlider(
                                values: _feeRange,
                                min: 0,
                                max: 50000,
                                divisions: 100,
                                onChanged: (values) => setState(() {
                                  _feeRange = values;
                                  _currentFilters = _currentFilters.copyWith(
                                    feeMin: values.start,
                                    feeMax: values.end,
                                  );
                                }),
                              ),
                            ),
                            // Read-only display synced with the slider — a single
                            // source of truth instead of editable duplicate fields.
                            Row(
                              children: [
                                Expanded(child: _buildValueBox('Min', '₹${_feeRange.start.toInt()}')),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('to', style: TextStyle(color: AppColors.textSecondary)),
                                ),
                                Expanded(child: _buildValueBox('Max', '₹${_feeRange.end.toInt()}')),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Age Group',
                      child: _buildSegmentedButtons(
                        options: ['All', 'Under-12', 'Under-14', 'Under-16', 'Under-18', 'Open'],
                        selected: _currentFilters.ageGroups.isNotEmpty ? _currentFilters.ageGroups.first : 'All',
                        onSelect: (age) {
                          setState(() {
                            _currentFilters = age == 'All'
                                ? _currentFilters.copyWith(ageGroups: [])
                                : _currentFilters.copyWith(ageGroups: [age]);
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Date Range',
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildPickerField(
                              label: 'From',
                              value: _currentFilters.dateFrom != null ? _fmtDate(_currentFilters.dateFrom!) : null,
                              hint: 'Select date',
                              icon: LucideIcons.calendar,
                              onTap: () => _pickDate(isFrom: true),
                              onClear: _currentFilters.dateFrom == null
                                  ? null
                                  : () => setState(() => _currentFilters = _currentFilters.copyWith(clearDateFrom: true)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildPickerField(
                              label: 'To',
                              value: _currentFilters.dateTo != null ? _fmtDate(_currentFilters.dateTo!) : null,
                              hint: 'Select date',
                              icon: LucideIcons.calendar,
                              onTap: () => _pickDate(isFrom: false),
                              onClear: _currentFilters.dateTo == null
                                  ? null
                                  : () => setState(() => _currentFilters = _currentFilters.copyWith(clearDateTo: true)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Gender',
                      child: _buildSegmentedButtons(
                        options: ['all', 'male', 'female'],
                        selected: _selectedGender,
                        display: (g) => g == 'all' ? 'All' : (g == 'male' ? 'Boys' : 'Girls'),
                        onSelect: (val) => setState(() {
                          _selectedGender = val;
                          _currentFilters = _currentFilters.copyWith(gender: val);
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: [
                  OutlinedButton(
                    onPressed: _clearAllFilters,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      foregroundColor: AppColors.textPrimary,
                    ),
                    child: const Text('Clear All Filters', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Apply Filters', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _cityNameById(MetaState meta, int id) {
    try {
      return meta.cities.firstWhere((c) => c.id == id).name;
    } catch (_) {
      return null;
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]} ${d.year}';

  String? _sportNameById(List<dynamic> sports, int id) {
    try {
      return sports.firstWhere((s) => s.id == id).name as String;
    } catch (_) {
      return null;
    }
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildChips({required List<String> options, required List<String> selected, required Function(String) onSelect}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = option == 'All Sports' ? selected.isEmpty : selected.contains(option);
        return GestureDetector(
          onTap: () => onSelect(option),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.background,
              border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              option,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSegmentedButtons({
    required List<String> options,
    required String selected,
    required Function(String) onSelect,
    String Function(String)? display,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((option) {
          final isSelected = selected == option;
          return GestureDetector(
            onTap: () => onSelect(option),
            child: Container(
              margin: EdgeInsets.only(right: option == options.last ? 0 : 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.background,
                border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                display != null ? display(option) : option,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Tappable picker field (date / city) — renders a single bordered box with
  /// the selected value; never an editable TextField, so there is no inner
  /// focused underline or duplicated input chrome.
  Widget _buildPickerField({
    required String label,
    required String? value,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  value ?? hint,
                  style: TextStyle(
                    fontSize: 14,
                    color: value != null ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (value != null && onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(LucideIcons.x, size: 16, color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _currentFilters = const SearchFilters();
      _selectedGender = 'all';
      _feeRange = const RangeValues(0, 30000);
      _feeEnabled = false;
    });
  }

  void _applyFilters() {
    ref.read(searchProvider.notifier).updateFilters(_currentFilters);
    context.pop();
  }
}
