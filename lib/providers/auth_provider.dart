import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../services/auth_service.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  onboardingRequired,
}

class AuthState {
  final AuthStatus status;
  final auth.User? user;
  final String? errorMessage;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    auth.User? user,
    String? errorMessage,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService authService;
  bool onboardingChecked = false;

  AuthNotifier(this.authService) : super(const AuthState()) {
    initAuthState();
  }

  void initAuthState() {
    // Listen to Firebase auth state changes to properly handle web session restore
    authService.authStateChanges.listen((user) {
      if (user != null) {
        // Set loading while we check onboarding
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          isLoading: true,
        );
        // Check onboarding only once
        if (!onboardingChecked) {
          checkOnboarding(user.uid);
        }
      } else {
        onboardingChecked = false;
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          user: null,
          isLoading: false,
        );
      }
    });
  }

  Future<void> checkOnboarding(String uid) async {
    if (onboardingChecked) return;
    onboardingChecked = true;
    final hasOnboarding = await authService.hasOnboardingCompleted(uid);
    if (!hasOnboarding) {
      state = state.copyWith(
        status: AuthStatus.onboardingRequired,
        isLoading: false,
      );
    } else {
      // Onboarding is complete, set loading to false
      state = state.copyWith(isLoading: false);
    }
  }

Future<void> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final user = await authService.signIn(email: email, password: password);
      if (user != null) {
        onboardingChecked = false;
        
        // Check onboarding status
        final hasOnboarding = await authService.hasOnboardingCompleted(user.uid);
        
        state = state.copyWith(
          status: hasOnboarding ? AuthStatus.authenticated : AuthStatus.onboardingRequired,
          user: user,
          isLoading: false,
        );
      } else {
        // User is null but no exception - shouldn't happen but handle it
        state = state.copyWith(
          errorMessage: 'Login failed. Please try again.',
          isLoading: false,
        );
      }
    } on AuthException catch (e) {
      state = state.copyWith(errorMessage: e.message, isLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: 'An error occurred', isLoading: false);
    }
  }

Future<void> signUp({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final user = await authService.signUp(email: email, password: password);
      if (user != null) {
        // Sign out after signup so user needs to manually log in
        await authService.signOut();
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          user: null,
          isLoading: false,
        );
      }
    } on AuthException catch (e) {
      state = state.copyWith(errorMessage: e.message, isLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: 'An error occurred', isLoading: false);
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);

    try {
      await authService.signOut();
      onboardingChecked = false;
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to sign out', isLoading: false);
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<void> completeOnboarding() async {
    final user = state.user;
    if (user == null) return;
    await authService.completeOnboarding(user.uid);
    state = state.copyWith(status: AuthStatus.authenticated);
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authSvc = ref.watch(authServiceProvider);
  return AuthNotifier(authSvc);
});

final currentUserProvider = Provider<auth.User?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.status == AuthStatus.authenticated || 
         authState.status == AuthStatus.onboardingRequired;
});

final onboardingRequiredProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.status == AuthStatus.onboardingRequired;
});
