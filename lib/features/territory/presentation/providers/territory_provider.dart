import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/services/h3_service.dart';
import '../../engine/capture_engine.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/constants/game_constants.dart';

final h3ServiceProvider = Provider<H3Service>((ref) => H3Service());

final captureEngineProvider = Provider<CaptureEngine>((ref) {
  return CaptureEngine(ref.watch(h3ServiceProvider));
});

class TerritoryCell {
  final String cellId;
  final String ownerId;
  final String ownerColor;
  final DateTime capturedAt;
  final bool isContested;
  const TerritoryCell({
    required this.cellId,
    required this.ownerId,
    required this.ownerColor,
    required this.capturedAt,
    this.isContested = false,
  });
}

class TerritoryState {
  final Map<String, TerritoryCell> ownedCells;
  final Set<String> playerCells;
  final int totalCaptured;
  final int xpEarned;
  final bool isLoading;
  const TerritoryState({
    this.ownedCells = const {},
    this.playerCells = const {},
    this.totalCaptured = 0,
    this.xpEarned = 0,
    this.isLoading = false,
  });
  TerritoryState copyWith({
    Map<String, TerritoryCell>? ownedCells,
    Set<String>? playerCells,
    int? totalCaptured,
    int? xpEarned,
    bool? isLoading,
  }) =>
      TerritoryState(
        ownedCells: ownedCells ?? this.ownedCells,
        playerCells: playerCells ?? this.playerCells,
        totalCaptured: totalCaptured ?? this.totalCaptured,
        xpEarned: xpEarned ?? this.xpEarned,
        isLoading: isLoading ?? this.isLoading,
      );
}

class TerritoryNotifier extends StateNotifier<TerritoryState> {
  static const String _selfColor = '#FF6D01';

  final CaptureEngine _captureEngine;
  final H3Service _h3Service;
  final String? _userId;
  final FirebaseFirestore _firestore;

  TerritoryNotifier(this._captureEngine, this._h3Service, this._userId, this._firestore) : super(const TerritoryState());

  Map<String, String> _allOwnedIds() {
    final allOwned = <String, String>{};
    for (final entry in state.ownedCells.entries) {
      allOwned[entry.key] = entry.value.ownerId;
    }
    return allOwned;
  }

  Map<String, TerritoryCell> _withCaptureApplied(CaptureResult result, DateTime at) {
    final next = Map<String, TerritoryCell>.from(state.ownedCells);
    for (final cellId in result.capturedCells) {
      next[cellId] = TerritoryCell(
        cellId: cellId,
        ownerId: _userId!,
        ownerColor: _selfColor,
        capturedAt: at,
        isContested: false,
      );
    }
    for (final cellId in result.contestedCells) {
      final prev = next[cellId];
      if (prev != null) {
        next[cellId] = TerritoryCell(
          cellId: cellId,
          ownerId: prev.ownerId,
          ownerColor: prev.ownerColor,
          capturedAt: prev.capturedAt,
          isContested: true,
        );
      }
    }
    return next;
  }

  Future<void> _commitCaptureBatches(CaptureResult result) async {
    const maxOps = 400;
    if (result.capturedCells.isNotEmpty) {
      for (var i = 0; i < result.capturedCells.length; i += maxOps) {
        final batch = _firestore.batch();
        final slice = result.capturedCells.sublist(
          i,
          i + maxOps > result.capturedCells.length ? result.capturedCells.length : i + maxOps,
        );
        for (final cellId in slice) {
          batch.set(_firestore.collection('territories').doc(cellId), {
            'ownerId': _userId,
            'ownerColor': _selfColor,
            'capturedAt': FieldValue.serverTimestamp(),
            'isContested': false,
          });
        }
        await batch.commit();
      }
    }
    if (result.contestedCells.isNotEmpty) {
      for (var i = 0; i < result.contestedCells.length; i += maxOps) {
        final batch = _firestore.batch();
        final slice = result.contestedCells.sublist(
          i,
          i + maxOps > result.contestedCells.length ? result.contestedCells.length : i + maxOps,
        );
        for (final cellId in slice) {
          batch.set(
            _firestore.collection('territories').doc(cellId),
            {'isContested': true, 'contestedBy': _userId},
            SetOptions(merge: true),
          );
        }
        await batch.commit();
      }
    }
  }

  Future<CaptureResult?> captureAtPosition(double lat, double lng) async {
    if (_userId == null) return null;
    state = state.copyWith(isLoading: true);
    final result = _captureEngine.captureAroundPosition(
      lat: lat,
      lng: lng,
      playerId: _userId,
      existingPlayerCells: state.playerCells,
      allOwnedCells: _allOwnedIds(),
    );
    await _commitCaptureBatches(result);
    final at = DateTime.now();
    state = state.copyWith(
      ownedCells: _withCaptureApplied(result, at),
      playerCells: {...state.playerCells, ...result.capturedCells.toSet()},
      totalCaptured: state.totalCaptured + result.totalCaptured,
      xpEarned: state.xpEarned + result.xpEarned,
      isLoading: false,
    );
    return result;
  }

  /// Auto-capture when the player closes a GPS loop (polygon interior → H3 polyfill).
  Future<CaptureResult?> captureClosedLoop(List<(double, double)> ring) async {
    if (_userId == null || ring.length < GameConstants.minLoopVertices) return null;
    final cellIds = _h3Service.cellsInsidePolygon(ring);
    if (cellIds.isEmpty) {
      return const CaptureResult(capturedCells: [], contestedCells: [], totalCaptured: 0, xpEarned: 0, wasContested: false);
    }
    state = state.copyWith(isLoading: true);
    final result = _captureEngine.captureFromCellIds(
      cellIds: cellIds,
      playerId: _userId,
      existingPlayerCells: state.playerCells,
      allOwnedCells: _allOwnedIds(),
    );
    await _commitCaptureBatches(result);
    final at = DateTime.now();
    state = state.copyWith(
      ownedCells: _withCaptureApplied(result, at),
      playerCells: {...state.playerCells, ...result.capturedCells.toSet()},
      totalCaptured: state.totalCaptured + result.totalCaptured,
      xpEarned: state.xpEarned + result.xpEarned,
      isLoading: false,
    );
    return result;
  }

  Future<void> loadTerritories(double lat, double lng, double radiusKm) async {
    state = state.copyWith(isLoading: true);
    try {
      final centerCell = _h3Service.latLngToCell(lat, lng);
      final k = (radiusKm / 0.5).ceil();
      final visibleCells = _h3Service.gridDisk(centerCell, k);
      final snapshot = await _firestore
          .collection('territories')
          .where(FieldPath.documentId, whereIn: visibleCells.sublist(0, visibleCells.length.clamp(0, 30)))
          .get();
      final cells = <String, TerritoryCell>{};
      final playerCells = <String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final cell = TerritoryCell(
          cellId: doc.id,
          ownerId: data['ownerId'] ?? '',
          ownerColor: data['ownerColor'] ?? '#1A73E8',
          capturedAt: (data['capturedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isContested: data['isContested'] ?? false,
        );
        cells[doc.id] = cell;
        if (cell.ownerId == _userId) playerCells.add(doc.id);
      }
      state = state.copyWith(ownedCells: cells, playerCells: playerCells, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  List<(double, double)> getCellBoundary(String cellId) => _h3Service.cellBoundary(cellId);
}

final territoryProvider = StateNotifierProvider<TerritoryNotifier, TerritoryState>((ref) {
  final userId = ref.watch(currentUserProvider)?.uid;
  return TerritoryNotifier(ref.watch(captureEngineProvider), ref.watch(h3ServiceProvider), userId, FirebaseFirestore.instance);
});
