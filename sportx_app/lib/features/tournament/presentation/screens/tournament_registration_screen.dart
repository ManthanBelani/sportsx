import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/shared/models/models.dart';
import 'package:sportx_app/shared/presentation/widgets/async_state_view.dart';
import 'package:sportx_app/shared/presentation/widgets/form_page_template.dart';
import 'package:sportx_app/shared/providers/activity_provider.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class TournamentRegistrationScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  const TournamentRegistrationScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<TournamentRegistrationScreen> createState() => _TournamentRegistrationScreenState();
}

class _TournamentRegistrationScreenState extends ConsumerState<TournamentRegistrationScreen> {
  final _teamController = TextEditingController();
  int? _categoryId;
  String _participationType = 'individual'; // individual | team
  bool _submitting = false;

  @override
  void dispose() {
    _teamController.dispose();
    super.dispose();
  }

  Future<void> _submit(Tournament tournament) async {
    final category = tournament.categories.where((c) => c.id == _categoryId).firstOrNull;
    if (category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }
    if (_participationType == 'team' && _teamController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a team name')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final response = await ref
          .read(dioProvider)
          .post('/tournaments/${widget.tournamentId}/register', data: {
            'category_id': category.id,
            'participation_type': _participationType,
            if (_participationType == 'team') 'team_name': _teamController.text.trim(),
          });

      if (!mounted) return;
      final data = response.data is Map ? response.data['data'] as Map<String, dynamic>? : null;
      final tournamentData = data?['tournament'] as Map<String, dynamic>?;
      ref.invalidate(activityProvider);
      context.push('/registration-confirmation', extra: {
        'is_trial': false,
        'registration_ref': 'TRN-${data?['id'] ?? ''}',
        'event_name': tournamentData?['name'],
        'event_date': tournamentData?['start_date']?.toString(),
        'venue': tournamentData?['venue'],
        'category': (data?['category'] as Map<String, dynamic>?)?['name']?.toString(),
      });
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.fromDio(e).message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(tournamentDetailProvider(widget.tournamentId));

    return AsyncDetailBuilder<Tournament>(
      async: async,
      title: 'Tournament Registration',
      onRetry: () => ref.invalidate(tournamentDetailProvider(widget.tournamentId)),
      dataBuilder: (tournament) {
        // Pick the first category by default once loaded.
        _categoryId ??= tournament.categories.firstOrNull?.id;

        final fee = tournament.registrationFee ?? 0;

        return FormPageTemplate(
          title: 'Tournament Registration',
          formFields: [
            _buildLabel('Participation Type'),
            Row(
              children: [
                _buildTypeOption('individual', 'Individual'),
                const SizedBox(width: 12),
                _buildTypeOption('team', 'Team'),
              ],
            ),
            const SizedBox(height: 16),
            if (_participationType == 'team') ...[
              _buildLabel('Team Name'),
              TextField(
                controller: _teamController,
                decoration: InputDecoration(
                  hintText: 'e.g. Elite Tigers',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            _buildLabel('Category'),
            DropdownButtonFormField<int>(
              value: _categoryId,
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
              items: tournament.categories
                  .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(
                          c.displayName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 16),
            if (fee > 0)
              Text(
                'Entry fee: ₹${fee.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
          ],
          ctaText: _submitting
              ? 'Submitting...'
              : fee > 0
                  ? 'Proceed to Payment (₹${fee.toStringAsFixed(0)})'
                  : 'Register',
          onSubmit: _submitting ? () {} : () => _submit(tournament),
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildTypeOption(String value, String label) {
    final isSelected = _participationType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _participationType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
