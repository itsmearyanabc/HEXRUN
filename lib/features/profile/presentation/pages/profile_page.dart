import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/profile_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(userProfileProvider(user?.uid ?? ''));
    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true, actions: [
        IconButton(icon: const Icon(Icons.logout), onPressed: () async {
          await ref.read(authStateProvider.notifier).signOut();
          if (context.mounted) context.go('/login');
        }),
      ]),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (profile) {
          if (profile == null) return const Center(child: Text('Profile not found'));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              CircleAvatar(radius: 60, backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(profile.displayName.isNotEmpty ? profile.displayName[0].toUpperCase() : '?',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer))),
              const SizedBox(height: 16),
              Text(profile.displayName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              Text(user?.email ?? '', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
              const SizedBox(height: 32),
              Row(children: [
                _StatCard(label: 'XP', value: '${profile.xp}', icon: Icons.star, color: Colors.amber),
                const SizedBox(width: 12),
                _StatCard(label: 'Hexes', value: '${profile.totalCells}', icon: Icons.hexagon, color: Colors.blue),
                const SizedBox(width: 12),
                _StatCard(label: 'Distance', value: '${profile.totalDistanceKm.toStringAsFixed(1)} km', icon: Icons.straighten, color: Colors.green),
              ]),
              const SizedBox(height: 32),
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Level ${profile.level}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text('${profile.xp} / ${profile.xpForNextLevel} XP', style: Theme.of(context).textTheme.bodySmall),
                ]),
                const SizedBox(height: 8),
                ClipRRect(borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(value: profile.levelProgress, minHeight: 12, backgroundColor: Theme.of(context).colorScheme.surfaceVariant)),
              ]))),
              const SizedBox(height: 24),
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Recent Runs', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (profile.recentRuns.isEmpty) const Text('No runs yet. Start running!')
                else ...profile.recentRuns.map((run) => ListTile(leading: const Icon(Icons.directions_run),
                  title: Text('${run.distanceKm.toStringAsFixed(2)} km'), subtitle: Text('${run.hexesCaptured} hexes'),
                  trailing: Text(_fmtDur(run.duration), style: Theme.of(context).textTheme.bodySmall))),
              ]))),
            ]),
          );
        },
      ),
    );
  }
  String _fmtDur(Duration d) { final m = d.inMinutes; final s = d.inSeconds.remainder(60); return m > 0 ? '${m}m ${s}s' : '${s}s'; }
}

class _StatCard extends StatelessWidget {
  final String label, value; final IconData icon; final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(12),
    child: Column(children: [Icon(icon, color: color, size: 28), const SizedBox(height: 4),
      Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      Text(label, style: Theme.of(context).textTheme.bodySmall)]))));
}