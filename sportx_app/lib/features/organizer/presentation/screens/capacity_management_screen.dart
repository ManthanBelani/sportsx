import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/theme/colors.dart';

class CapacityManagementScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  const CapacityManagementScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<CapacityManagementScreen> createState() => _CapacityManagementScreenState();
}

class _CapacityManagementScreenState extends ConsumerState<CapacityManagementScreen> {
  int? _totalSpots;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.tournamentId.isEmpty) return;
    try {
      final resp = await ref.read(dioProvider).get('/tournaments/${widget.tournamentId}/capacity');
      final data = resp.data is Map && resp.data['data'] is Map
          ? resp.data['data'] as Map<String, dynamic>
          : resp.data as Map<String, dynamic>;
      setState(() => _totalSpots = data['total_spots'] as int?);
    } catch (_) {}
  }

  Future<void> _save() async {
    if (_totalSpots == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(dioProvider).put('/tournaments/${widget.tournamentId}/capacity', data: {
        'total_spots': _totalSpots,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Capacity saved')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Manage Capacity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Total Spots', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: _totalSpots == null ? null : () => setState(() => _totalSpots = (_totalSpots! > 0 ? _totalSpots! - 1 : 0)),
                icon: const Icon(LucideIcons.minus),
              ),
              Text('${_totalSpots ?? '—'}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              IconButton(
                onPressed: _totalSpots == null ? null : () => setState(() => _totalSpots = _totalSpots! + 1),
                icon: const Icon(LucideIcons.plus),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (_saving || _totalSpots == null) ? null : _save,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }
}
