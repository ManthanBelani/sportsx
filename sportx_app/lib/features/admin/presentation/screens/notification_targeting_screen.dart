import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sportx_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:sportx_app/features/admin/presentation/screens/admin_web_layout.dart';
import 'package:sportx_app/theme/colors.dart';

class NotificationTargetingScreen extends ConsumerStatefulWidget {
  const NotificationTargetingScreen({super.key});

  @override
  ConsumerState<NotificationTargetingScreen> createState() =>
      _NotificationTargetingScreenState();
}

class _NotificationTargetingScreenState
    extends ConsumerState<NotificationTargetingScreen> {
  final Set<String> _selectedRoles = {};
  final Set<String> _selectedSports = {};
  final Set<String> _selectedCities = {};
  bool _selectByRole = false;
  bool _selectBySport = false;
  bool _selectByCity = false;

  @override
  Widget build(BuildContext context) {
    return AdminWebLayout(
      title: 'Advanced Targeting',
      actions: [
        TextButton(
          onPressed: _applyTargeting,
          child: const Text('Apply'),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildRoleFilter(),
          const SizedBox(height: 24),
          _buildSportFilter(),
          const SizedBox(height: 24),
          _buildCityFilter(),
          const SizedBox(height: 24),
          _buildTargetingSummary(),
          const SizedBox(height: 24),
          _buildApplyButton(),
        ],
      ),
    );
  }

  Widget _buildRoleFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AdminSectionLabel(label: 'Filter by Role'),
                const Spacer(),
                Switch(
                  value: _selectByRole,
                  onChanged: (value) {
                    setState(() {
                      _selectByRole = value;
                      if (!value) _selectedRoles.clear();
                    });
                  },
                ),
              ],
            ),
            if (_selectByRole) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip('Athletes', 'athlete'),
                  _buildFilterChip('Coaches', 'coach'),
                  _buildFilterChip('Sponsors', 'sponsor'),
                  _buildFilterChip('Academies', 'academy'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSportFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AdminSectionLabel(label: 'Filter by Sport'),
                const Spacer(),
                Switch(
                  value: _selectBySport,
                  onChanged: (value) {
                    setState(() {
                      _selectBySport = value;
                      if (!value) _selectedSports.clear();
                    });
                  },
                ),
              ],
            ),
            if (_selectBySport) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip('Cricket', 'cricket'),
                  _buildFilterChip('Football', 'football'),
                  _buildFilterChip('Basketball', 'basketball'),
                  _buildFilterChip('Tennis', 'tennis'),
                  _buildFilterChip('Badminton', 'badminton'),
                  _buildFilterChip('Hockey', 'hockey'),
                  _buildFilterChip('Volleyball', 'volleyball'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCityFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AdminSectionLabel(label: 'Filter by City'),
                const Spacer(),
                Switch(
                  value: _selectByCity,
                  onChanged: (value) {
                    setState(() {
                      _selectByCity = value;
                      if (!value) _selectedCities.clear();
                    });
                  },
                ),
              ],
            ),
            if (_selectByCity) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip('Mumbai', 'mumbai'),
                  _buildFilterChip('Delhi', 'delhi'),
                  _buildFilterChip('Bangalore', 'bangalore'),
                  _buildFilterChip('Chennai', 'chennai'),
                  _buildFilterChip('Kolkata', 'kolkata'),
                  _buildFilterChip('Hyderabad', 'hyderabad'),
                  _buildFilterChip('Pune', 'pune'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedRoles.contains(value) ||
        _selectedSports.contains(value) ||
        _selectedCities.contains(value);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (_selectByRole && ['athlete', 'coach', 'sponsor', 'academy'].contains(value)) {
            if (selected) {
              _selectedRoles.add(value);
            } else {
              _selectedRoles.remove(value);
            }
          }
          if (_selectBySport && ['cricket', 'football', 'basketball', 'tennis', 'badminton', 'hockey', 'volleyball'].contains(value)) {
            if (selected) {
              _selectedSports.add(value);
            } else {
              _selectedSports.remove(value);
            }
          }
          if (_selectByCity && ['mumbai', 'delhi', 'bangalore', 'chennai', 'kolkata', 'hyderabad', 'pune'].contains(value)) {
            if (selected) {
              _selectedCities.add(value);
            } else {
              _selectedCities.remove(value);
            }
          }
        });
      },
      selectedColor: AppColors.primary.withOpacity(0.1),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildTargetingSummary() {
    final hasFilters = _selectedRoles.isNotEmpty ||
        _selectedSports.isNotEmpty ||
        _selectedCities.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionLabel(label: 'Targeting Summary'),
            const SizedBox(height: 16),
            if (!hasFilters)
              Text(
                'No filters selected. Notification will be sent to all users.',
                style: TextStyle(color: AppColors.textSecondary),
              )
            else ...[
              if (_selectedRoles.isNotEmpty) ...[
                _buildSummarySection('Roles', _selectedRoles.toList()),
                const SizedBox(height: 12),
              ],
              if (_selectedSports.isNotEmpty) ...[
                _buildSummarySection('Sports', _selectedSports.toList()),
                const SizedBox(height: 12),
              ],
              if (_selectedCities.isNotEmpty)
                _buildSummarySection('Cities', _selectedCities.toList()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title:',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            return Chip(
              label: Text(item.toUpperCase()),
              backgroundColor: AppColors.primaryLight,
              labelStyle: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildApplyButton() {
    return ElevatedButton(
      onPressed: _applyTargeting,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text(
        'Apply Targeting Filters',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _applyTargeting() {
    final targeting = {
      if (_selectedRoles.isNotEmpty) 'roles': _selectedRoles.toList(),
      if (_selectedSports.isNotEmpty) 'sports': _selectedSports.toList(),
      if (_selectedCities.isNotEmpty) 'cities': _selectedCities.toList(),
    };

    Navigator.pop(context, targeting);
  }
}
