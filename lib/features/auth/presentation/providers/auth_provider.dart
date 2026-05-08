import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/failures.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    firebaseAuth: firebase_auth.FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    googleSignIn: GoogleSignIn(),
  );
});

/// Auth state notifier
class AuthStateNotifier extends StateNotifier<AsyncValue<UserEntity?>> {
  final AuthRepository _authRepository;

  AuthStateNotifier(this._authRepository)
      : super(const AsyncValue.loading()) {
    _authRepository.authStateChanges.listen(
      (user) {
        state = AsyncValue.data(user);
      },
      onError: (error) {
        state = AsyncValue.error(error, StackTrace.current);
      },
    );
  }

  Future<void> signInWithEmailAndPassword(
      String email, String password) async {
    state = const AsyncValue.loading();
    final result = await _authRepository.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (user) => state = AsyncValue.data(user),
    );
  }

  Future<void> signUpWithEmailAndPassword(
      String email, String password, String displayName) async {
    state = const AsyncValue.loading();
    final result = await _authRepository.signUpWithEmailAndPassword(
      email: email,
      password: password,
      displayName: displayName,
    );
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (user) => state = AsyncValue.data(user),
    );
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    final result = await _authRepository.signInWithGoogle();
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (user) => state = AsyncValue.data(user),
    );
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    state = const AsyncValue.data(null);
  }
}

/// Auth state provider
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AsyncValue<UserEntity?>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthStateNotifier(repository);
});

/// Whether user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value != null;
});

/// Current user entity
final currentUserProvider = Provider<UserEntity?>((ref) {
  return ref.watch(authStateProvider).value;
});