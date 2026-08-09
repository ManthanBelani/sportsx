import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
        title: const Text('Saved'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Academies'),
            Tab(text: 'Trials'),
            Tab(text: 'Tournaments'),
            Tab(text: 'Scholarships'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSavedList(),
          _buildSavedList(),
          _buildSavedList(),
          _buildSavedList(),
          _buildSavedList(),
        ],
      ),
    );
  }

  Widget _buildSavedList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ListTile(
          leading: Icon(Icons.favorite, color: Colors.red),
          title: Text('Elite Cricket Academy'),
          subtitle: Text('Cricket · Ahmedabad'),
        ),
        Divider(),
        ListTile(
          leading: Icon(Icons.favorite, color: Colors.red),
          title: Text('U-16 State Cricket Cup'),
          subtitle: Text('Tournament · 15 Aug 2026'),
        ),
        Divider(),
        ListTile(
          leading: Icon(Icons.favorite, color: Colors.red),
          title: Text('State Sports Scholarship 2026'),
          subtitle: Text('Scholarship · Deadline: Tomorrow'),
        ),
      ],
    );
  }
}
