import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminContentPickerScreen extends StatelessWidget {
  const AdminContentPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCategoryTile(context, '🏫', 'Academies', '412', '/admin-content-list/academies'),
          _buildCategoryTile(context, '🧑‍🏫', 'Coaches', '238', '/admin-content-list/coaches'),
          _buildCategoryTile(context, '🏆', 'Trials', '89', '/admin-content-list/trials'),
          _buildCategoryTile(context, '🏟', 'Tournaments', '24', '/admin-content-list/tournaments'),
          _buildCategoryTile(context, '🎓', 'Scholarships', '15', '/admin-content-list/scholarships'),
          _buildCategoryTile(context, '💼', 'Sponsorships', '31', '/admin-content-list/sponsorships'),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(BuildContext context, String emoji, String name, String count, String route) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(emoji, style: const TextStyle(fontSize: 28)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(count, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[300]!),
        ),
        onTap: () => context.push(route),
      ),
    );
  }
}
