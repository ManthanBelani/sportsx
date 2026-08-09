import 'package:flutter/material.dart';
import 'package:sportx_app/theme/colors.dart';

class ConnectionRequestsScreen extends StatefulWidget {
  const ConnectionRequestsScreen({super.key});

  @override
  State<ConnectionRequestsScreen> createState() => _ConnectionRequestsScreenState();
}

class _ConnectionRequestsScreenState extends State<ConnectionRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock received requests
  final List<Map<String, dynamic>> _receivedRequests = [
    {
      'id': 'r1',
      'name': 'Vikram Mehta',
      'avatar': 'https://i.pravatar.cc/150?img=25',
      'sport': 'Cricket',
      'level': 'State Level',
      'message': 'Hi, I\'d like to connect for training sessions.',
    },
    {
      'id': 'r2',
      'name': 'Neha Gupta',
      'avatar': 'https://i.pravatar.cc/150?img=26',
      'sport': 'Badminton',
      'level': 'District Level',
      'message': 'Let\'s practice together!',
    },
    {
      'id': 'r3',
      'name': 'Raj Sports Academy',
      'avatar': 'https://i.pravatar.cc/150?img=28',
      'sport': 'Multi-sport',
      'level': 'Academy',
      'message': 'Join our training program.',
    },
  ];

  // Mock sent requests
  final List<Map<String, dynamic>> _sentRequests = [
    {
      'id': 's1',
      'name': 'Coach Rajesh',
      'avatar': 'https://i.pravatar.cc/150?img=30',
      'sport': 'Football',
      'level': 'Coach',
      'status': 'pending',
    },
    {
      'id': 's2',
      'name': 'Mumbai Tigers FC',
      'avatar': 'https://i.pravatar.cc/150?img=32',
      'sport': 'Football',
      'level': 'Club',
      'status': 'pending',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Requests'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Received (${_receivedRequests.length})'),
            Tab(text: 'Sent (${_sentRequests.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReceivedTab(),
          _buildSentTab(),
        ],
      ),
    );
  }

  Widget _buildReceivedTab() {
    if (_receivedRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              'No pending requests',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _receivedRequests.length,
      itemBuilder: (context, index) {
        final request = _receivedRequests[index];
        return _buildReceivedRequestCard(request);
      },
    );
  }

  Widget _buildReceivedRequestCard(Map<String, dynamic> request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(request['avatar']),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${request['sport']} · ${request['level']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (request['message'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  request['message'],
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _declineRequest(request);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _acceptRequest(request);
                    },
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentTab() {
    if (_sentRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send_outlined, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              'No sent requests',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sentRequests.length,
      itemBuilder: (context, index) {
        final request = _sentRequests[index];
        return _buildSentRequestCard(request);
      },
    );
  }

  Widget _buildSentRequestCard(Map<String, dynamic> request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          backgroundImage: NetworkImage(request['avatar']),
        ),
        title: Text(
          request['name'],
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${request['sport']} · ${request['level']}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Pending',
            style: TextStyle(
              color: AppColors.warning,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  void _acceptRequest(Map<String, dynamic> request) {
    setState(() {
      _receivedRequests.removeWhere((r) => r['id'] == request['id']);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Connected with ${request['name']}')),
    );
  }

  void _declineRequest(Map<String, dynamic> request) {
    setState(() {
      _receivedRequests.removeWhere((r) => r['id'] == request['id']);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Request from ${request['name']} declined')),
    );
  }
}
