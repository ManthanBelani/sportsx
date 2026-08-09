import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AcademyProfilePostingScreen extends StatelessWidget {
  const AcademyProfilePostingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Academy Listing'),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.camera_alt, color: Colors.grey, size: 40),
            ),
            const SizedBox(height: 8),
            Center(child: TextButton(onPressed: () {}, child: const Text('Upload Cover Photo'))),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Name', hintText: 'Elite Cricket Acad')),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Sport(s)', hintText: 'Cricket')),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Facilities', hintText: 'Turf, Nets, Gym')),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Fee Range', hintText: '₹2000 – ₹5000/mo')),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Age Groups', hintText: 'U-12, U-16, Open')),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Timings', hintText: '6–9AM, 4–7PM')),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Coaches', hintText: '+ Add Coach')),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Photos', hintText: '+ Add Photos')),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Academy Updated!')));
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
