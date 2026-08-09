import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sportx_app/shared/presentation/widgets/form_page_template.dart';

class TournamentRegistrationScreen extends StatelessWidget {
  final String tournamentId;
  const TournamentRegistrationScreen({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context) {
    return FormPageTemplate(
      title: 'Tournament Registration',
      autoFilledProfile: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Manager: Rahul Mehta', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('Club: Elite Sports Academy'),
        ],
      ),
      formFields: [
        Text('Team Name', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: 'e.g. Elite Tigers',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        Text('Category', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          value: 'U-19 Boys',
          items: const [
            DropdownMenuItem(value: 'U-19 Boys', child: Text('U-19 Boys')),
            DropdownMenuItem(value: 'Open Mens', child: Text('Open Mens')),
          ],
          onChanged: (v) {},
        ),
      ],
      ctaText: 'Proceed to Payment (₹5,000)',
      onSubmit: () {
        context.push('/registration-confirmation');
      },
    );
  }
}
