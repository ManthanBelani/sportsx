import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/shared/presentation/widgets/form_page_template.dart';
import 'package:sportx_app/theme/colors.dart';

class TournamentRegistrationScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  const TournamentRegistrationScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<TournamentRegistrationScreen> createState() => _TournamentRegistrationScreenState();
}

class _TournamentRegistrationScreenState extends ConsumerState<TournamentRegistrationScreen> {
  final _teamController = TextEditingController();
  String _category = 'U-19 Boys';
  bool _submitting = false;

  @override
  void dispose() {
    _teamController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref.read(dioProvider).post('/tournaments/${widget.tournamentId}/register', data: {
        'team_name': _teamController.text.trim(),
        'category': _category,
      });
      if (mounted) context.push('/registration-confirmation');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormPageTemplate(
      title: 'Tournament Registration',
      formFields: [
        Text('Team Name', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _teamController,
          decoration: InputDecoration(
            hintText: 'e.g. Elite Tigers',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        Text('Category', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _category,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: const [
            DropdownMenuItem(value: 'U-19 Boys', child: Text('U-19 Boys')),
            DropdownMenuItem(value: 'Open Mens', child: Text('Open Mens')),
          ],
          onChanged: (v) => setState(() => _category = v ?? 'U-19 Boys'),
        ),
      ],
      ctaText: _submitting ? 'Submitting...' : 'Proceed to Payment (₹5,000)',
      onSubmit: _submitting ? () {} : _submit,
    );
  }
}
