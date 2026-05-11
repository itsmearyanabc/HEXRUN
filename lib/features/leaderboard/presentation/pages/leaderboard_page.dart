import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/leaderboard_provider.dart';

class LeaderboardPage extends ConsumerWidget {
  const LeaderboardPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard'), centerTitle: true),
      body: leaderboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (entries) {
          if (entries.isEmpty) return const Center(child: Text('No players yet. Start running!'));
          return ListView.builder(
            padding: const EdgeInsets.all(16), itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final rank = index + 1;
              return Card(
                elevation: rank <= 3 ? 4 : 1, margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: _RankBadge(rank: rank),
                  title: Text(entry.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${entry.totalCells} hexes captured'),
                  trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${entry.xp} XP', style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                    Text('${entry.totalDistanceKm.toStringAsFixed(1)} km', style: Theme.of(context).textTheme.bodySmall),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});
  @override
  Widget build(BuildContext context) {
    final color = rank == 1 ? Colors.amber : rank == 2 ? Colors.grey.shade400 : rank == 3 ? Colors.brown : Theme.of(context).colorScheme.surfaceContainerHighest;
    return CircleAvatar(
      backgroundColor: color.withAlpha(50),
      child: rank <= 3 ? Icon(Icons.emoji_events, color: color, size: 24) : Text('$rank', style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}