import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/organizer/presentation/providers/organizer_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class ResultsPublishingScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final String title;
  const ResultsPublishingScreen({
    super.key,
    required this.tournamentId,
    required this.title,
  });

  @override
  ConsumerState<ResultsPublishingScreen> createState() => _ResultsPublishingScreenState();
}

class _ResultsPublishingScreenState extends ConsumerState<ResultsPublishingScreen> {
  final _winnerController = TextEditingController();
  final _runnerUpController = TextEditingController();
  final _thirdController = TextEditingController();
  String _category = 'u14';
  bool _saving = false;

  @override
  void dispose() {
    _winnerController.dispose();
    _runnerUpController.dispose();
    _thirdController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    setState(() => _saving = true);
    try {
      await ref.read(dioProvider).post('/tournaments/${widget.tournamentId}/results', data: {
        'category': _category,
        'winner': _winnerController.text.trim(),
        'runner_up': _runnerUpController.text.trim(),
        'third_place': _thirdController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Results saved!')));
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
        title: Text('Results: ${widget.title}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: const [
                DropdownMenuItem(value: 'u14', child: Text('U-14')),
                DropdownMenuItem(value: 'u16', child: Text('U-16')),
                DropdownMenuItem(value: 'u18', child: Text('U-18')),
              ],
              onChanged: (v) => setState(() => _category = v ?? 'u14'),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _winnerController,
              decoration: const InputDecoration(labelText: 'Winner', hintText: 'Team Titans'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _runnerUpController,
              decoration: const InputDecoration(labelText: 'Runner-up', hintText: 'Team Strikers'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _thirdController,
              decoration: const InputDecoration(labelText: '3rd Place', hintText: 'Team Falcons'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _publish,
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                child: _saving
                    ? const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Publish Results'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
