import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

/// Firebase implementation of AuthRepository
class AuthRepositoryImpl implements AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRepositoryImpl({
    required firebase_auth.FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    required GoogleSignIn googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore,
        _googleSignIn = googleSignIn;

  @override
  Stream<UserEntity?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      
      // Try to get user from firestore with retries for new accounts
      UserEntity? entity;
      for (int i = 0; i < 3; i++) {
        entity = await _getUserFromFirestore(firebaseUser.uid);
        if (entity != null) break;
        print('AUTH: User document not found yet, retrying... ($i)');
        await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
      }
      
      // Fallback: If still null, return a basic entity so we don't get kicked out
      if (entity == null) {
        print('AUTH: Using fallback UserEntity for ${firebaseUser.uid}');
        return UserEntity(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? 'New User',
        );
      }
      
      return entity;
    });
  }

  @override
  UserEntity? get currentUser {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;
    return UserEntity(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? '',
      photoUrl: firebaseUser.photoURL ?? '',
    );
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('AUTH: Starting sign in for $email');
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        print('AUTH: User is null after sign in');
        return Left(Failure.auth(message: 'Sign in failed'));
      }
      print('AUTH: Firebase Auth success, fetching user ${user.uid} from Firestore');
      
      // Try to get user from firestore, with a small retry if needed
      UserEntity? entity = await _getUserFromFirestore(user.uid);
      
      if (entity == null) {
        print('AUTH: User data not found in Firestore for ${user.uid}');
        return Left(Failure.auth(message: 'User data not found. Please try signing up again.'));
      }
      
      print('AUTH: Successfully fetched user entity');
      await _updateOnlineStatus(user.uid, true);
      return Right(entity);
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('AUTH: FirebaseAuthException: ${e.code} - ${e.message}');
      return Left(Failure.auth(message: e.message ?? 'Authentication failed'));
    } catch (e) {
      print('AUTH: Unknown error during sign in: $e');
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      print('AUTH: Starting sign up for $email');
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        print('AUTH: User is null after sign up');
        return Left(Failure.auth(message: 'Sign up failed'));
      }
      print('AUTH: Firebase Auth account created: ${user.uid}');
      await user.updateDisplayName(displayName);

      final newUser = UserEntity(
        uid: user.uid,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
        lastSeen: DateTime.now(),
        isOnline: true,
      );

      print('AUTH: Saving user data to Firestore');
      await _firestore.collection('users').doc(user.uid).set({
        ...newUser.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
      });
      print('AUTH: User data saved successfully');

      return Right(newUser);
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('AUTH: FirebaseAuthException during sign up: ${e.code} - ${e.message}');
      return Left(Failure.auth(message: e.message ?? 'Authentication failed'));
    } catch (e) {
      print('AUTH: Unknown error during sign up: $e');
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return Left(Failure.auth(message: 'Google sign in cancelled'));
      }

      final googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        return Left(Failure.auth(message: 'Google sign in failed'));
      }

      final existingUser = await _getUserFromFirestore(user.uid);
      if (existingUser == null) {
        final newUser = UserEntity(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '',
          photoUrl: user.photoURL ?? '',
          createdAt: DateTime.now(),
          lastSeen: DateTime.now(),
          isOnline: true,
        );
        await _firestore.collection('users').doc(user.uid).set({
          ...newUser.toJson(),
          'createdAt': FieldValue.serverTimestamp(),
          'lastSeen': FieldValue.serverTimestamp(),
        });
        return Right(newUser);
      }

      await _updateOnlineStatus(user.uid, true);
      return Right(existingUser);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(Failure.auth(message: e.message ?? 'Authentication failed'));
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await _updateOnlineStatus(user.uid, false);
      }
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
      return const Right(null);
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    String? displayName,
    String? photoUrl,
    String? color,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return Left(Failure.auth(message: 'Not authenticated'));
      }

      final updates = <String, dynamic>{};
      if (displayName != null) {
        updates['displayName'] = displayName;
        await user.updateDisplayName(displayName);
      }
      if (photoUrl != null) {
        updates['photoUrl'] = photoUrl;
        await user.updatePhotoURL(photoUrl);
      }
      if (color != null) updates['color'] = color;

      if (updates.isNotEmpty) {
        updates['lastSeen'] = FieldValue.serverTimestamp();
        await _firestore.collection('users').doc(user.uid).update(updates);
      }

      final updated = await _getUserFromFirestore(user.uid);
      if (updated == null) {
        return Left(
            Failure.server(message: 'Failed to fetch updated profile'));
      }
      return Right(updated);
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return Left(Failure.auth(message: 'Not authenticated'));
      }
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
      return const Right(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return Left(
            Failure.auth(message: 'Please re-authenticate to delete account'));
      }
      return Left(Failure.auth(message: e.message ?? 'Authentication failed'));
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  Future<UserEntity?> _getUserFromFirestore(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserEntity.fromJson(doc.data()!);
  }

  Future<void> _updateOnlineStatus(String uid, bool isOnline) async {
    await _firestore.collection('users').doc(uid).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }
}