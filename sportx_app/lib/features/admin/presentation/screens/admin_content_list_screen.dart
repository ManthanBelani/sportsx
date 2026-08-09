import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminContentListScreen extends StatelessWidget {
  final String category;
  const AdminContentListScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final displayName = category[0].toUpperCase() + category.substring(1);
    return Scaffold(
      appBar: AppBar(
        title: Text(displayName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/admin-content-edit/$category/new'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search $displayName...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 10,
              itemBuilder: (context, i) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text('$displayName Item ${i + 1}'),
                  subtitle: Text(i % 3 == 0 ? 'Active' : i % 3 == 1 ? 'Draft' : 'Expired',
                      style: TextStyle(
                        color: i % 3 == 0 ? Colors.green : i % 3 == 1 ? Colors.orange : Colors.red,
                      )),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => context.push('/admin-content-edit/$category/${i + 1}'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Record'),
                              content: const Text('Are you sure you want to delete this record?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                FilledButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record deleted')));
                                  },
                                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                  onTap: () => context.push('/admin-content-edit/$category/${i + 1}'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
