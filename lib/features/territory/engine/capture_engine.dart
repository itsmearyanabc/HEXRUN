import '../data/services/h3_service.dart';
import '../../../../core/constants/game_constants.dart';

/// Result of a capture operation
class CaptureResult {
  final List<String> capturedCells;
  final List<String> contestedCells;
  final int totalCaptured;
  final int xpEarned;
  final bool wasContested;
  const CaptureResult({required this.capturedCells, required this.contestedCells, required this.totalCaptured, required this.xpEarned, required this.wasContested});
}

/// Territory capture engine - handles hex cell capture logic
class CaptureEngine {
  final H3Service _h3Service;
  CaptureEngine(this._h3Service);

  /// Capture cells around a given position
  CaptureResult captureAroundPosition({
    required double lat, required double lng, required String playerId,
    required Set<String> existingPlayerCells, required Map<String, String> allOwnedCells,
  }) {
    final centerCell = _h3Service.latLngToCell(lat, lng);
    final cellsInRadius = _h3Service.gridDisk(centerCell, GameConstants.captureRadiusK);
    final capturedCells = <String>[];
    final contestedCells = <String>[];

    for (final cell in cellsInRadius) {
      if (existingPlayerCells.contains(cell)) continue;
      final currentOwner = allOwnedCells[cell];
      if (currentOwner == null) {
        capturedCells.add(cell);
      } else if (currentOwner != playerId) {
        contestedCells.add(cell);
      }
    }

    final int totalXp = (capturedCells.length * GameConstants.xpPerCapture) + (contestedCells.length * GameConstants.xpPerContest);
    return CaptureResult(capturedCells: capturedCells, contestedCells: contestedCells,
      totalCaptured: capturedCells.length, xpEarned: totalXp, wasContested: contestedCells.isNotEmpty);
  }

  /// Check if a player can capture a specific cell
  bool canCaptureCell({required String cellId, required String playerId, required Set<String> playerCells}) {
    if (playerCells.contains(cellId)) return true;
    final neighbors = _h3Service.gridDisk(cellId, 1);
    for (final neighbor in neighbors) {
      if (playerCells.contains(neighbor)) return true;
    }
    return false;
  }

  /// Get frontier cells (unclaimed cells adjacent to owned cells)
  Set<String> getFrontierCells(Set<String> playerCells, Map<String, String> allOwnedCells) {
    final frontier = <String>{};
    for (final cell in playerCells) {
      final neighbors = _h3Service.gridDisk(cell, 1);
      for (final neighbor in neighbors) {
        if (!playerCells.contains(neighbor) && !allOwnedCells.containsKey(neighbor)) {
          frontier.add(neighbor);
        }
      }
    }
    return frontier;
  }

  /// Calculate cluster bonus for connected cells
  int calculateClusterBonus(Set<String> playerCells) {
    if (playerCells.isEmpty) return 0;
    return (playerCells.length ~/ 10) * GameConstants.clusterBonusXp;
  }
}