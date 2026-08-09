import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ActivityHubScreen extends StatelessWidget {
  const ActivityHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Activity'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Trials'),
              Tab(text: 'Tournaments'),
              Tab(text: 'Sponsorships'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildActivityList([
              _ActivityItem('U-14 Cricket Trial', 'Registered', Colors.green, '15 Aug 2026'),
              _ActivityItem('U-16 Athletics Sprint', 'Pending', Colors.orange, '22 Aug 2026'),
            ]),
            _buildActivityList([
              _ActivityItem('U-16 State Cup', 'Registered', Colors.green, '20–25 Aug 2026'),
            ]),
            _buildActivityList([
              _ActivityItem('U-16 Cricket Kit', 'Applied', Colors.blue, 'Deadline: 30 Sep 2026'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityList(List<_ActivityItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
                    Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(item.date, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: item.statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(item.status, style: TextStyle(color: item.statusColor, fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActivityItem {
  final String title;
  final String status;
  final Color statusColor;
  final String date;
  _ActivityItem(this.title, this.status, this.statusColor, this.date);
}
