import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

/// Auth repository contract
abstract class AuthRepository {
  /// Get current authenticated user stream
  Stream<UserEntity?> get authStateChanges;

  /// Get current user
  UserEntity? get currentUser;

  /// Sign in with email and password
  Future<Either<Failure, UserEntity>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Sign up with email and password
  Future<Either<Failure, UserEntity>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  });

  /// Sign in with Google
  Future<Either<Failure, UserEntity>> signInWithGoogle();

  /// Sign out
  Future<Either<Failure, void>> signOut();

  /// Update user profile
  Future<Either<Failure, UserEntity>> updateProfile({
    String? displayName,
    String? photoUrl,
    String? color,
  });

  /// Delete account
  Future<Either<Failure, void>> deleteAccount();
}