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
import 'package:sportx_app/core/utils/snackbar_utils.dart';

class TournamentRegistrationScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  const TournamentRegistrationScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<TournamentRegistrationScreen> createState() => _TournamentRegistrationScreenState();
}

class _TournamentRegistrationScreenState extends ConsumerState<TournamentRegistrationScreen> {
  final _teamController = TextEditingController();
  final _teamManagerController = TextEditingController();
  final _captainNameController = TextEditingController();
  final _coachNameController = TextEditingController();
  int? _numberOfPlayers;
  int? _categoryId;
  String _participationType = 'individual'; // individual | team
  bool _submitting = false;

  @override
  void dispose() {
    _teamController.dispose();
    _teamManagerController.dispose();
    _captainNameController.dispose();
    _coachNameController.dispose();
    super.dispose();
  }

  Future<void> _submit(Tournament tournament) async {
    final category = tournament.categories.where((c) => c.id == _categoryId).firstOrNull;
    if (category == null) {
      SnackBarUtils.showSuccess(context, 'Please select a category');
      return;
    }
    if (_participationType == 'team' && _teamController.text.trim().isEmpty) {
      SnackBarUtils.showSuccess(context, 'Please enter a team name');
      return;
    }
    if (_participationType == 'team') {
      if (_numberOfPlayers == null) {
        SnackBarUtils.showSuccess(context, 'Please select number of players');
        return;
      }
      if (_captainNameController.text.trim().isEmpty) {
        SnackBarUtils.showSuccess(context, 'Please enter captain name');
        return;
      }
    }

    setState(() => _submitting = true);
    try {
      final response = await ref
          .read(dioProvider)
          .post('/tournaments/${widget.tournamentId}/register', data: {
            'category_id': category.id,
            'participation_type': _participationType,
            if (_participationType == 'team') ...{
              'team_name': _teamController.text.trim(),
              'team_manager': _teamManagerController.text.trim(),
              'captain_name': _captainNameController.text.trim(),
              'coach_name': _coachNameController.text.trim(),
              'number_of_players': _numberOfPlayers ?? 0,
            },
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
        SnackBarUtils.showError(context, (() { final ex = ApiException.fromDio(e); return ex.fieldErrors.isNotEmpty ? '${ex.message} (${ex.fieldErrors.values.join(', ')})' : ex.message; })());
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, e, 'Registration failed. Please check your connection and try again.');
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
              _buildLabel('Team Manager'),
              TextField(
                controller: _teamManagerController,
                decoration: InputDecoration(
                  hintText: 'Manager name (optional)',
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
              _buildLabel('Number of Players'),
              DropdownButtonFormField<int>(
                initialValue: _numberOfPlayers,
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
                  hintText: 'Select players',
                ),
                hint: const Text('Select players', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                items: List.generate(15, (i) => i + 8)
                    .map((n) => DropdownMenuItem(value: n, child: Text('$n players')))
                    .toList(),
                onChanged: (v) => setState(() => _numberOfPlayers = v),
              ),
              const SizedBox(height: 16),
              _buildLabel('Captain Name'),
              TextField(
                controller: _captainNameController,
                decoration: InputDecoration(
                  hintText: 'Captain name',
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
              _buildLabel('Coach Name'),
              TextField(
                controller: _coachNameController,
                decoration: InputDecoration(
                  hintText: 'Coach name (optional)',
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
              initialValue: _categoryId,
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Entry fee ₹${fee.toStringAsFixed(0)} (approval required — pay only if instructed by the organizer)',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          ctaText: _submitting ? 'Submitting...' : 'Request to Participate',
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
