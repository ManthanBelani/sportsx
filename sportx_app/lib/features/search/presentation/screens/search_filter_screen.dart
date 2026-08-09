import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/search/presentation/providers/search_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class SearchFilterScreen extends ConsumerStatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  ConsumerState<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends ConsumerState<SearchFilterScreen> {
  late SearchFilters _currentFilters;

  final List<String> _allSports = [
    'All Sports',
    'Football',
    'Basketball',
    'Cricket',
    'Athletics',
    'Swimming',
    'Tennis',
    'Badminton',
  ];

  final List<String> _allAgeGroups = [
    '5-8',
    '8-12',
    '12-16',
    '16-20',
    '20+',
  ];

  final List<String> _genders = ['All', 'Boys', 'Girls'];
  final List<String> _ratings = ['All', '4+ ★', '3+ ★'];

  String _selectedGender = 'All';
  String _selectedRating = 'All';
  RangeValues _feeRange = const RangeValues(0, 30000);

  @override
  void initState() {
    super.initState();
    _currentFilters = ref.read(searchProvider).filters;
  }

  @override
  Widget build(BuildContext context) {
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
                      child: _buildChips(
                        options: _allSports,
                        selected: _currentFilters.sports.isEmpty ? ['All Sports'] : _currentFilters.sports,
                        onSelect: (sport) {
                          setState(() {
                            if (sport == 'All Sports') {
                              _currentFilters = _currentFilters.copyWith(sports: []);
                            } else {
                              final sports = List<String>.from(_currentFilters.sports);
                              if (sports.contains(sport)) {
                                sports.remove(sport);
                              } else {
                                sports.add(sport);
                              }
                              _currentFilters = _currentFilters.copyWith(sports: sports);
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Location',
                      child: Row(
                        children: [
                          Expanded(child: _buildTextField('City', 'Bangalore')),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField('State', 'Karnataka')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Fee Range (per month)',
                      child: Column(
                        children: [
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
                              onChanged: (values) => setState(() => _feeRange = values),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(child: _buildTextField('Min', '₹${_feeRange.start.toInt()}')),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text('to', style: TextStyle(color: AppColors.textSecondary)),
                              ),
                              Expanded(child: _buildTextField('Max', '₹${_feeRange.end.toInt()}')),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Age Group',
                      child: _buildSegmentedButtons(
                        options: _allAgeGroups,
                        selected: _currentFilters.ageGroups.isNotEmpty ? _currentFilters.ageGroups.first : '12-16',
                        onSelect: (age) {
                          setState(() {
                            _currentFilters = _currentFilters.copyWith(ageGroups: [age]);
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Date Range',
                      child: Row(
                        children: [
                          Expanded(child: _buildTextField('From', '2024-11-01')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildTextField('To', '2024-12-31')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Gender',
                      child: _buildSegmentedButtons(
                        options: _genders,
                        selected: _selectedGender,
                        onSelect: (val) => setState(() => _selectedGender = val),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Rating',
                      child: _buildSegmentedButtons(
                        options: _ratings,
                        selected: _selectedRating,
                        onSelect: (val) => setState(() => _selectedRating = val),
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
                    child: const Text('Apply Filters (24 results)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
        final isSelected = selected.contains(option);
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

  Widget _buildSegmentedButtons({required List<String> options, required String selected, required Function(String) onSelect}) {
    return Row(
      children: options.map((option) {
        final isSelected = selected == option;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(option),
            child: Container(
              margin: EdgeInsets.only(right: option == options.last ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.background,
                border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField(String hint, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        initialValue: value,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _currentFilters = SearchFilters();
      _selectedGender = 'All';
      _selectedRating = 'All';
      _feeRange = const RangeValues(0, 30000);
    });
  }

  void _applyFilters() {
    ref.read(searchProvider.notifier).updateFilters(_currentFilters);
    context.pop();
  }
}
