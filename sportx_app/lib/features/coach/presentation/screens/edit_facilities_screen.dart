import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sportx_app/features/coach/presentation/providers/coach_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class EditFacilitiesScreen extends ConsumerStatefulWidget {
  const EditFacilitiesScreen({super.key});

  @override
  ConsumerState<EditFacilitiesScreen> createState() => _EditFacilitiesScreenState();
}

class _EditFacilitiesScreenState extends ConsumerState<EditFacilitiesScreen> {
  final List<Map<String, dynamic>> _facilities = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingFacilities();
  }

  void _loadExistingFacilities() {
    final coachState = ref.read(coachProvider);
    setState(() {
      _facilities.addAll(
        coachState.facilities.map((f) => Map<String, dynamic>.from(f)).toList(),
      );
    });
    if (_facilities.isEmpty) {
      _addNewFacility();
    }
  }

  void _addNewFacility() {
    setState(() {
      _facilities.add({
        'name': '',
        'description': '',
        'type': 'facility',
      });
    });
  }

  void _removeFacility(int index) {
    if (_facilities.length > 1) {
      setState(() {
        _facilities.removeAt(index);
      });
    }
  }

  Future<void> _saveFacilities() async {
    // Validate all facilities
    for (int i = 0; i < _facilities.length; i++) {
      if (_facilities[i]['name'].toString().trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter a name for facility ${i + 1}')),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      await ref.read(coachProvider.notifier).updateFacilities(_facilities);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Facilities updated successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update facilities: $e')),
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
        title: const Text('Edit Facilities & Programs'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _facilities.length,
              itemBuilder: (context, index) {
                return _buildFacilityCard(index);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _addNewFacility,
                icon: const Icon(Icons.add),
                label: const Text('Add Another'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveFacilities,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Facilities'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityCard(int index) {
    final facility = _facilities[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Facility ${index + 1}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_facilities.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: () => _removeFacility(index),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: facility['name'],
              decoration: const InputDecoration(
                labelText: 'Facility / Program Name',
                hintText: 'e.g., Indoor Cricket Nets',
              ),
              onChanged: (value) {
                _facilities[index]['name'] = value;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: facility['description'],
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe this facility or program...',
                alignLabelWithHint: true,
              ),
              onChanged: (value) {
                _facilities[index]['description'] = value;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: facility['type'] ?? 'facility',
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: 'facility', child: Text('Facility')),
                DropdownMenuItem(value: 'program', child: Text('Program')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _facilities[index]['type'] = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
