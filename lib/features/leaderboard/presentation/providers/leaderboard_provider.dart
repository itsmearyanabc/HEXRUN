import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardEntry {
  final String userId;
  final String displayName;
  final int xp;
  final int totalCells;
  final double totalDistanceKm;
  final String avatarUrl;
  const LeaderboardEntry({required this.userId, required this.displayName, required this.xp, required this.totalCells, required this.totalDistanceKm, this.avatarUrl = ''});
}

final leaderboardProvider = StreamProvider<List<LeaderboardEntry>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .orderBy('xp', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
        final data = doc.data();
        return LeaderboardEntry(
          userId: doc.id,
          displayName: data['displayName'] ?? 'Unknown',
          xp: (data['xp'] as num?)?.toInt() ?? 0,
          totalCells: (data['totalCells'] as num?)?.toInt() ?? 0,
          totalDistanceKm: (data['totalDistanceKm'] as num?)?.toDouble() ?? 0.0,
          avatarUrl: data['avatarUrl'] ?? '',
        );
      }).toList());
});