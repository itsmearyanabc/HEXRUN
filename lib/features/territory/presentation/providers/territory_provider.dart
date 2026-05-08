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
  const TerritoryCell({required this.cellId, required this.ownerId, required this.ownerColor, required this.capturedAt, this.isContested = false});
}

class TerritoryState {
  final Map<String, TerritoryCell> ownedCells;
  final Set<String> playerCells;
  final int totalCaptured;
  final int xpEarned;
  final bool isLoading;
  const TerritoryState({this.ownedCells = const {}, this.playerCells = const {}, this.totalCaptured = 0, this.xpEarned = 0, this.isLoading = false});
  TerritoryState copyWith({Map<String, TerritoryCell>? ownedCells, Set<String>? playerCells, int? totalCaptured, int? xpEarned, bool? isLoading}) =>
      TerritoryState(ownedCells: ownedCells ?? this.ownedCells, playerCells: playerCells ?? this.playerCells,
        totalCaptured: totalCaptured ?? this.totalCaptured, xpEarned: xpEarned ?? this.xpEarned, isLoading: isLoading ?? this.isLoading);
}

class TerritoryNotifier extends StateNotifier<TerritoryState> {
  final CaptureEngine _captureEngine;
  final H3Service _h3Service;
  final String? _userId;
  final FirebaseFirestore _firestore;

  TerritoryNotifier(this._captureEngine, this._h3Service, this._userId, this._firestore) : super(const TerritoryState());

  Future<CaptureResult?> captureAtPosition(double lat, double lng) async {
    if (_userId == null) return null;
    state = state.copyWith(isLoading: true);
    final allOwned = <String, String>{};
    for (final entry in state.ownedCells.entries) {
      allOwned[entry.key] = entry.value.ownerId;
    }
    final result = _captureEngine.captureAroundPosition(
      lat: lat, lng: lng, playerId: _userId!, existingPlayerCells: state.playerCells, allOwnedCells: allOwned,
    );
    final batch = _firestore.batch();
    for (final cellId in result.capturedCells) {
      batch.set(_firestore.collection('territories').doc(cellId),
        {'ownerId': _userId, 'capturedAt': FieldValue.serverTimestamp(), 'isContested': false});
    }
    for (final cellId in result.contestedCells) {
      batch.update(_firestore.collection('territories').doc(cellId), {'isContested': true, 'contestedBy': _userId});
    }
    await batch.commit();
    state = state.copyWith(
      playerCells: {...state.playerCells, ...result.capturedCells.toSet()},
      totalCaptured: state.totalCaptured + result.totalCaptured, xpEarned: state.xpEarned + result.xpEarned, isLoading: false,
    );
    return result;
  }

  Future<void> loadTerritories(double lat, double lng, double radiusKm) async {
    state = state.copyWith(isLoading: true);
    try {
      final centerCell = _h3Service.latLngToCell(lat, lng);
      final k = (radiusKm / 0.5).ceil();
      final visibleCells = _h3Service.gridDisk(centerCell, k);
      final snapshot = await _firestore.collection('territories')
          .where(FieldPath.documentId, whereIn: visibleCells.sublist(0, visibleCells.length.clamp(0, 30))).get();
      final cells = <String, TerritoryCell>{};
      final playerCells = <String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final cell = TerritoryCell(cellId: doc.id, ownerId: data['ownerId'] ?? '', ownerColor: data['ownerColor'] ?? '#1A73E8',
          capturedAt: (data['capturedAt'] as Timestamp?)?.toDate() ?? DateTime.now(), isContested: data['isContested'] ?? false);
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