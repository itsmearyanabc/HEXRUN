import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RunRecord {
  final double distanceKm;
  final int hexesCaptured;
  final Duration duration;
  final DateTime date;
  const RunRecord({required this.distanceKm, required this.hexesCaptured, required this.duration, required this.date});
}

class UserProfile {
  final String displayName;
  final int xp;
  final int totalCells;
  final double totalDistanceKm;
  final int level;
  final int xpForNextLevel;
  final double levelProgress;
  final List<RunRecord> recentRuns;
  const UserProfile({required this.displayName, required this.xp, required this.totalCells, required this.totalDistanceKm,
    required this.level, required this.xpForNextLevel, required this.levelProgress, this.recentRuns = const []});
}

final userProfileProvider = StreamProvider.family<UserProfile?, String>((ref, userId) {
  if (userId.isEmpty) return Stream.value(null);
  return FirebaseFirestore.instance.collection('users').doc(userId).snapshots().map((doc) {
    if (!doc.exists) return null;
    final data = doc.data()!;
    final xp = (data['xp'] as num?)?.toInt() ?? 0;
    final level = (xp / 500).floor() + 1;
    final xpForCurrentLevel = (level - 1) * 500;
    final xpForNextLevel = level * 500;
    final progress = (xp - xpForCurrentLevel) / (xpForNextLevel - xpForCurrentLevel);
    final runs = (data['recentRuns'] as List?)?.map((r) => RunRecord(
      distanceKm: (r['distanceKm'] as num?)?.toDouble() ?? 0,
      hexesCaptured: (r['hexesCaptured'] as num?)?.toInt() ?? 0,
      duration: Duration(seconds: (r['durationSec'] as num?)?.toInt() ?? 0),
      date: (r['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    )).toList() ?? [];
    return UserProfile(displayName: data['displayName'] ?? 'Unknown', xp: xp,
      totalCells: (data['totalCells'] as num?)?.toInt() ?? 0,
      totalDistanceKm: (data['totalDistanceKm'] as num?)?.toDouble() ?? 0,
      level: level, xpForNextLevel: xpForNextLevel, levelProgress: progress.clamp(0.0, 1.0), recentRuns: runs);
  });
});