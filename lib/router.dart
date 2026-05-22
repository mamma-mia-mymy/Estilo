import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'qna_intro_screen.dart';
import 'demographic_screen.dart';
import 'skin_tone_screen.dart';
import 'style_preferences_screen.dart';
import 'home_page.dart';
import 'features/outfits/screens/profile_screen.dart';
import 'features/outfits/screens/outfit_screen.dart';
import 'features/outfits/screens/add_wardrobe_item_screen.dart';
import 'features/mix_match/screens/mix_match_screen.dart';
import 'features/mix_match/screens/creation_hub_screen.dart';
import 'features/mix_match/screens/upload_photo_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      // Always allow access to login and signup pages
      final isAuthRoute = state.matchedLocation == '/login' || 
                        state.matchedLocation == '/signup';
      
      // Skip redirect during initial loading - let the UI handle it
      if (authState.status == AuthStatus.initial) {
        return null;
      }

      // If loading, don't redirect - stay on current page
      if (authState.isLoading) {
        return null;
      }

      // If needs onboarding and not on login/signup, go to onboarding
      // BUT allow navigation between all main app routes
      if (authState.status == AuthStatus.onboardingRequired) {
        final isOnboardingRoute = state.matchedLocation.startsWith('/onboarding');
        // Allow all main app routes - user is authenticated, just hasn't completed onboarding setup
        final isMainAppRoute = state.matchedLocation == '/home' ||
                             state.matchedLocation == '/profile' ||
                             state.matchedLocation.startsWith('/outfits') ||
                             state.matchedLocation == '/add-wardrobe-item' ||
                             state.matchedLocation.startsWith('/creation-hub') ||
                             state.matchedLocation == '/mix-match';
        
        if (!isOnboardingRoute && !isMainAppRoute) {
          return '/onboarding';
        }
        return null;
      }

      // If authenticated and on login/signup, go to home
      if (authState.status == AuthStatus.authenticated) {
        if (isAuthRoute) {
          return '/home';
        }
        return null;
      }

      // If not authenticated and not on login/signup, go to login
      if (authState.status == AuthStatus.unauthenticated) {
        if (!isAuthRoute) {
          return '/login';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const QnAIntroScreen(),
      ),
      GoRoute(
        path: '/onboarding/demographic',
        builder: (context, state) => const DemographicScreen(),
      ),
      GoRoute(
        path: '/onboarding/skin-tone',
        builder: (context, state) => const SkinToneScreen(),
      ),
      GoRoute(
        path: '/onboarding/style',
        builder: (context, state) => const StylePreferencesScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/outfits',
        builder: (context, state) => const OutfitsScreen(),
      ),
      GoRoute(
        path: '/add-wardrobe-item',
        builder: (context, state) => const AddWardrobeItemScreen(),
      ),
      GoRoute(
        path: '/mix-match',
        builder: (context, state) => const MixMatchScreen(),
      ),
      GoRoute(
        path: '/creation-hub',
        builder: (context, state) => const CreationHubScreen(),
        routes: [
          GoRoute(
            path: 'upload',
            builder: (context, state) => const UploadPhotoScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
