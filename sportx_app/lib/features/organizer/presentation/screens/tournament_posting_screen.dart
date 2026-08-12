import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/organizer/presentation/providers/organizer_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class TournamentPostingScreen extends ConsumerStatefulWidget {
  const TournamentPostingScreen({super.key});

  @override
  ConsumerState<TournamentPostingScreen> createState() => _TournamentPostingScreenState();
}

class _TournamentPostingScreenState extends ConsumerState<TournamentPostingScreen> {
  final _name = TextEditingController();
  final _dates = TextEditingController();
  final _venue = TextEditingController();
  final _fee = TextEditingController();
  final _prize = TextEditingController();
  final _categories = TextEditingController();
  String _format = 'knockout';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _dates.dispose();
    _venue.dispose();
    _fee.dispose();
    _prize.dispose();
    _categories.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await ref.read(providerTournamentActionsProvider).create({
      'title': _name.text.trim(),
      'format': _format,
      'start_date': _dates.text.trim(),
      'venue': _venue.text.trim(),
      'registration_fee': num.tryParse(_fee.text.trim()) ?? 0,
      'prize_pool': num.tryParse(_prize.text.trim()) ?? 0,
      'categories': _categories.text.trim(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tournament saved!')));
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Create Tournament',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Tournament Name', hintText: 'e.g. U-16 State Cup')),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _format,
              decoration: const InputDecoration(labelText: 'Format'),
              items: const [
                DropdownMenuItem(value: 'knockout', child: Text('Knockout')),
                DropdownMenuItem(value: 'league', child: Text('League')),
              ],
              onChanged: (v) => setState(() => _format = v ?? 'knockout'),
            ),
            const SizedBox(height: 16),
            TextField(controller: _dates, decoration: const InputDecoration(labelText: 'Start Date', hintText: 'YYYY-MM-DD')),
            const SizedBox(height: 16),
            TextField(controller: _venue, decoration: const InputDecoration(labelText: 'Venue')),
            const SizedBox(height: 16),
            TextField(controller: _fee, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Entry Fee', hintText: 'e.g. 500')),
            const SizedBox(height: 16),
            TextField(controller: _prize, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prize Pool', hintText: 'e.g. 50000')),
            const SizedBox(height: 16),
            TextField(controller: _categories, decoration: const InputDecoration(labelText: 'Categories', hintText: 'e.g. U-14, U-16')),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save & Publish'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
