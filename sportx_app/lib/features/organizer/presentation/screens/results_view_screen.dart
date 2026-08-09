import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResultsViewScreen extends StatelessWidget {
  const ResultsViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('U-16 State Cup — Results'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bracket', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('Quarterfinal', style: Theme.of(context).textTheme.labelSmall),
                      Text('Semifinal', style: Theme.of(context).textTheme.labelSmall),
                      Text('Final', style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildBracketRow('Titans', 'Falcons', 'Titans'),
                  const SizedBox(height: 8),
                  _buildBracketRow('Strikers', 'Eagles', 'Strikers'),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🏆 ', style: TextStyle(fontSize: 20)),
                        Text('Titans', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMedalCard('🥇', 'Titans', context),
                _buildMedalCard('🥈', 'Strikers', context),
                _buildMedalCard('🥉', 'Falcons', context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBracketRow(String team1, String team2, String winner) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _buildTeamChip(team1, team1 == winner),
              const SizedBox(height: 4),
              _buildTeamChip(team2, team2 == winner),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward, size: 16),
        Expanded(
          child: Center(child: _buildTeamChip(winner, true)),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildTeamChip(String name, bool isWinner) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isWinner ? Colors.green.withOpacity(0.15) : Colors.grey[200],
        borderRadius: BorderRadius.circular(6),
        border: isWinner ? Border.all(color: Colors.green) : null,
      ),
      child: Text(name, style: TextStyle(fontWeight: isWinner ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
    );
  }

  Widget _buildMedalCard(String medal, String team, BuildContext context) {
    return Column(
      children: [
        Text(medal, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 4),
        Text(team, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}
