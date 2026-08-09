import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SponsorPitchScreen extends StatelessWidget {
  final String sponsorId;
  const SponsorPitchScreen({super.key, required this.sponsorId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply for Sponsorship'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Your sport profile (achievements, media) will be automatically attached to this pitch.'),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Why are you a good fit?', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                hintText: 'Write a cover letter / pitch note...',
                border: OutlineInputBorder(),
              ),
              maxLines: 8,
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Additional Link (Optional)',
                hintText: 'e.g. YouTube highlight reel',
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  context.push('/registration-confirmation');
                },
                child: const Text('Submit Application'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
