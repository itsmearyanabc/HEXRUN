import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the map is ready for interaction
final mapReadyProvider = StateProvider<bool>((ref) => false);