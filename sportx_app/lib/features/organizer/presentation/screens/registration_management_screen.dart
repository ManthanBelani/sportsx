import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegistrationManagementScreen extends StatefulWidget {
  const RegistrationManagementScreen({super.key});

  @override
  State<RegistrationManagementScreen> createState() => _RegistrationManagementScreenState();
}

class _RegistrationManagementScreenState extends State<RegistrationManagementScreen> {
  int _selectedTab = 0;
  final _tabs = ['U-14 (18/24)', 'U-16 (22/24)', 'U-18 (9/24)'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrations: U-16 State Cup'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: List.generate(_tabs.length, (index) {
                final isSelected = _selectedTab == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          _tabs[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildTeamCard('Team Titans', true),
                const SizedBox(height: 12),
                _buildTeamCard('Team Strikers', false),
                const SizedBox(height: 12),
                _buildTeamCard('Team Falcons', true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(String teamName, bool isPaid) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(teamName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Row(
            children: [
              Icon(
                isPaid ? Icons.check_circle : Icons.warning,
                size: 16,
                color: isPaid ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 4),
              Text(isPaid ? 'Paid ✅' : 'Pending ⚠', style: TextStyle(color: isPaid ? Colors.green : Colors.orange)),
            ],
          ),
        ],
      ),
    );
  }
}
