import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegistrantListScreen extends StatelessWidget {
  const RegistrantListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrants: U-14 Trials'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('34 registered', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('6 spots left', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildRegistrantCard(context, 'Aryan Patel', true),
                const SizedBox(height: 12),
                _buildRegistrantCard(context, 'Meera Shah', false),
                const SizedBox(height: 12),
                _buildRegistrantCard(context, 'Rohan Kumar', true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrantCard(BuildContext context, String name, bool docsSubmitted) {
    return InkWell(
      onTap: () => context.push('/registrant-detail'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Docs: ', style: TextStyle(color: Colors.grey[600])),
                      Icon(
                        docsSubmitted ? Icons.check_circle : Icons.warning,
                        size: 16,
                        color: docsSubmitted ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(docsSubmitted ? 'Submitted' : 'Pending',
                          style: TextStyle(color: docsSubmitted ? Colors.green : Colors.orange)),
                    ],
                  ),
                ],
              ),
            ),
            TextButton(onPressed: () => context.push('/registrant-detail'), child: const Text('View →')),
          ],
        ),
      ),
    );
  }
}
