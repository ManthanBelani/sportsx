import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CoachProfilePostingScreen extends StatelessWidget {
  const CoachProfilePostingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit My Listing'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Save'),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.camera_alt, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () {}, child: const Text('Upload Profile Photo')),
            const SizedBox(height: 24),
            const TextField(decoration: InputDecoration(labelText: 'Name', hintText: 'Rahul Mehta')),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Sport(s)', hintText: 'Cricket')),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Certifications', hintText: '+ Add / Edit')),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Experience', hintText: '8 years')),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Fee Structure', hintText: '₹800 / session')),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Location', hintText: 'Ahmedabad')),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(labelText: 'Bio', hintText: 'Tell athletes about yourself...'),
              maxLines: 4,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated!')));
                  context.pop();
                },
                child: const Text('Save Changes'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
