import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

/// Custom exceptions for authentication errors.
class AuthException implements Exception {
  final String message;
  final AuthErrorType type;

  const AuthException({
    required this.message,
    required this.type,
  });

  @override
  String toString() => message;
}

enum AuthErrorType {
  invalidEmail,
  weakPassword,
  emailAlreadyInUse,
  invalidCredentials,
  networkError,
  unknown,
}

/// Service for handling Firebase Authentication and Firestore user operations.
///
/// This service manages:
/// - User sign up with email/password
/// - User sign in
/// - User sign out
/// - Firestore user document creation
class AuthService {
  final auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({
    auth.FirebaseAuth? authInstance,
    FirebaseFirestore? firestoreInstance,
  })  : _auth = authInstance ?? auth.FirebaseAuth.instance,
        _firestore = firestoreInstance ?? FirebaseFirestore.instance;

  /// The users collection reference.
  CollectionReference get _usersRef =>
      _firestore.collection('users');

  /// Signs in a user with email and password.
  ///
  /// Throws [AuthException] if authentication fails.
  Future<auth.User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // Ensure user document exists (in case it wasn't created during signup)
        try {
          final doc = await _usersRef.doc(user.uid).get();
          if (!doc.exists) {
            await _createUserDocument(user.uid, email.trim());
          }
        } catch (e) {
          print('Warning: Failed to ensure user document: $e');
          // Don't throw - user is already authenticated
        }
      }

      return user;
    } on auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AuthException(
        message: 'An unexpected error occurred. Please try again.',
        type: AuthErrorType.unknown,
      );
    }
  }

  /// Signs up a new user with email and password.
  ///
  /// Creates a new Firebase Authentication account and a corresponding
  /// Firestore user document.
  ///
  /// Throws [AuthException] if signup fails.
  Future<auth.User?> signUp({
    required String email,
    required String password,
  }) async {
    try {
      // Create Firebase Auth account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthException(
          message: 'Failed to create account. Please try again.',
          type: AuthErrorType.unknown,
        );
      }

      // Create Firestore user document with timeout
      try {
        await _createUserDocument(user.uid, email)
            .timeout(const Duration(seconds: 10));
      } catch (e) {
        print('Warning: Failed to create user document: $e');
        // Don't throw - user is already created in Firebase Auth
        // The document will be created on first login if needed
      }

      return user;
    } on auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        message: 'An unexpected error occurred. Please try again.',
        type: AuthErrorType.unknown,
      );
    }
  }

  /// Creates a user document in Firestore.
  ///
  /// This document stores user profile information and onboarding status.
  Future<void> _createUserDocument(String uid, String email) async {
    await _usersRef.doc(uid).set({
      'uid': uid,
      'email': email.toLowerCase().trim(),
      'onboardingCompleted': false,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Updates a user's profile data in Firestore.
  Future<void> updateUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await _usersRef.doc(uid).update({
      ...data,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Marks a user's onboarding as complete.
  Future<void> completeOnboarding(String uid) async {
    await _usersRef.doc(uid).update({
      'onboardingCompleted': true,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

/// Checks if a user has completed onboarding.
  Future<bool> hasOnboardingCompleted(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get()
          .timeout(const Duration(seconds: 5));
      if (!doc.exists) return false;
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return false;
      return data['onboardingCompleted'] ?? false;
    } catch (e) {
      print('Error checking onboarding status: $e');
      // Return false on error - user will see onboarding
      return false;
    }
  }

  /// Gets the current authenticated user.
  auth.User? get currentUser => _auth.currentUser;

  /// Signs out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Listens to authentication state changes.
  Stream<auth.User?> get authStateChanges =>
      _auth.authStateChanges();

  /// Handles Firebase Auth exceptions and converts them to [AuthException].
  AuthException _handleAuthException(auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return const AuthException(
          message: 'Invalid email address format',
          type: AuthErrorType.invalidEmail,
        );
      case 'weak-password':
        return const AuthException(
          message: 'Password is too weak. Please use a stronger password.',
          type: AuthErrorType.weakPassword,
        );
      case 'email-already-in-use':
        return const AuthException(
          message: 'This email is already registered',
          type: AuthErrorType.emailAlreadyInUse,
        );
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return const AuthException(
          message: 'Invalid email or password',
          type: AuthErrorType.invalidCredentials,
        );
      case 'network-request-failed':
        return const AuthException(
          message: 'Network error. Please check your connection.',
          type: AuthErrorType.networkError,
        );
      case 'user-disabled':
        return const AuthException(
          message: 'This account has been disabled',
          type: AuthErrorType.invalidCredentials,
        );
      default:
        return AuthException(
          message: 'Authentication failed. Please try again.',
          type: AuthErrorType.unknown,
        );
    }
  }
}
