import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sportx_app/theme/colors.dart';

class MyConnectionsScreen extends StatefulWidget {
  const MyConnectionsScreen({super.key});

  @override
  State<MyConnectionsScreen> createState() => _MyConnectionsScreenState();
}

class _MyConnectionsScreenState extends State<MyConnectionsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Mock connections data
  final List<Map<String, dynamic>> _connections = [
    {
      'id': '1',
      'name': 'Rohit Sharma',
      'avatar': 'https://i.pravatar.cc/150?img=3',
      'sport': 'Cricket',
      'level': 'State Level',
    },
    {
      'id': '2',
      'name': 'Priya Patel',
      'avatar': 'https://i.pravatar.cc/150?img=5',
      'sport': 'Badminton',
      'level': 'National Level',
    },
    {
      'id': '3',
      'name': 'Akash Kumar',
      'avatar': 'https://i.pravatar.cc/150?img=8',
      'sport': 'Football',
      'level': 'District Level',
    },
    {
      'id': '4',
      'name': 'Sneha Reddy',
      'avatar': 'https://i.pravatar.cc/150?img=9',
      'sport': 'Tennis',
      'level': 'State Level',
    },
    {
      'id': '5',
      'name': 'Coach Vikram',
      'avatar': 'https://i.pravatar.cc/150?img=12',
      'sport': 'Athletics',
      'level': 'Coach',
    },
    {
      'id': '6',
      'name': 'Delhi Sports Academy',
      'avatar': 'https://i.pravatar.cc/150?img=15',
      'sport': 'Multi-sport',
      'level': 'Academy',
    },
    {
      'id': '7',
      'name': 'Arjun Singh',
      'avatar': 'https://i.pravatar.cc/150?img=18',
      'sport': 'Hockey',
      'level': 'National Level',
    },
    {
      'id': '8',
      'name': 'Meera Joshi',
      'avatar': 'https://i.pravatar.cc/150?img=20',
      'sport': 'Swimming',
      'level': 'State Level',
    },
  ];

  List<Map<String, dynamic>> get _filteredConnections {
    if (_searchQuery.isEmpty) return _connections;
    return _connections.where((c) =>
      c['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
      c['sport'].toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Connections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => context.push('/connection-requests'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              decoration: InputDecoration(
                hintText: 'Search connections...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _filteredConnections.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: AppColors.textTertiary),
                        const SizedBox(height: 16),
                        Text(
                          'No connections found',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredConnections.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final connection = _filteredConnections[index];
                      return _buildConnectionTile(connection);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionTile(Map<String, dynamic> connection) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(connection['avatar']),
      ),
      title: Text(
        connection['name'],
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${connection['sport']} · ${connection['level']}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            color: AppColors.primary,
            onPressed: () {
              context.push('/chat-screen', extra: {
                'id': connection['id'],
                'name': connection['name'],
                'avatar': connection['avatar'],
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            color: AppColors.textSecondary,
            onPressed: () {
              _showMoreOptions(connection);
            },
          ),
        ],
      ),
      onTap: () {
        context.push('/view-profile', extra: {
          'type': 'athlete',
          'id': connection['id'],
        });
      },
    );
  }

  void _showMoreOptions(Map<String, dynamic> connection) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                context.push('/view-profile', extra: {
                  'type': 'athlete',
                  'id': connection['id'],
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Send Message'),
              onTap: () {
                Navigator.pop(context);
                context.push('/chat-screen', extra: {
                  'id': connection['id'],
                  'name': connection['name'],
                  'avatar': connection['avatar'],
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: const Text('Add to Favorites'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added to favorites')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.person_remove, color: AppColors.error),
              title: Text('Remove Connection', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                _confirmRemove(connection);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemove(Map<String, dynamic> connection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Connection'),
        content: Text('Remove ${connection['name']} from your connections?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _connections.removeWhere((c) => c['id'] == connection['id']);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Connection removed')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
