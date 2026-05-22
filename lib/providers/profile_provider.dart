import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_storage/firebase_storage.dart';

/// User profile data model
class UserProfile {
  final String uid;
  final String? email;
  final String? name;
  final String? gender;
  final String? bodyType;
  final String? skinTone;
  final List<String> styles;
  final List<String> colors;
  final List<String> occasions;
  final String? clothingSize;
  final String? profileImageUrl;
  final bool onboardingCompleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.uid,
    this.email,
    this.name,
    this.gender,
    this.bodyType,
    this.skinTone,
    this.styles = const [],
    this.colors = const [],
    this.occasions = const [],
    this.clothingSize,
    this.profileImageUrl,
    this.onboardingCompleted = false,
    this.createdAt,
    this.updatedAt,
  });

  UserProfile copyWith({
    String? uid,
    String? email,
    String? name,
    String? gender,
    String? bodyType,
    String? skinTone,
    List<String>? styles,
    List<String>? colors,
    List<String>? occasions,
    String? clothingSize,
    String? profileImageUrl,
    bool? onboardingCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      bodyType: bodyType ?? this.bodyType,
      skinTone: skinTone ?? this.skinTone,
      styles: styles ?? this.styles,
      colors: colors ?? this.colors,
      occasions: occasions ?? this.occasions,
      clothingSize: clothingSize ?? this.clothingSize,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return UserProfile(
      uid: doc.id,
      email: data?['email'] as String?,
      name: data?['name'] as String?,
      gender: data?['gender'] as String?,
      bodyType: data?['bodyType'] as String?,
      skinTone: data?['skinTone'] as String?,
      styles: (data?['styles'] as List<dynamic>?)?.cast<String>() ?? [],
      colors: (data?['colors'] as List<dynamic>?)?.cast<String>() ?? [],
      occasions: (data?['occasions'] as List<dynamic>?)?.cast<String>() ?? [],
      clothingSize: data?['clothingSize'] as String?,
      profileImageUrl: data?['profileImageUrl'] as String?,
      onboardingCompleted: data?['onboardingCompleted'] as bool? ?? false,
      createdAt: data?['createdAt'] != null
          ? DateTime.parse(data!['createdAt'])
          : null,
      updatedAt: data?['updatedAt'] != null
          ? DateTime.parse(data!['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (email != null) 'email': email,
      if (name != null) 'name': name,
      if (gender != null) 'gender': gender,
      if (bodyType != null) 'bodyType': bodyType,
      if (skinTone != null) 'skinTone': skinTone,
      if (styles.isNotEmpty) 'styles': styles,
      if (colors.isNotEmpty) 'colors': colors,
      if (occasions.isNotEmpty) 'occasions': occasions,
      if (clothingSize != null) 'clothingSize': clothingSize,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      'onboardingCompleted': onboardingCompleted,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }
}

/// Profile state
class ProfileState {
  final UserProfile? profile;
  final bool isLoading;
  final String? errorMessage;
  final bool isSaving;

  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.errorMessage,
    this.isSaving = false,
  });

  ProfileState copyWith({
    UserProfile? profile,
    bool? isLoading,
    String? errorMessage,
    bool? isSaving,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

/// Profile notifier
class ProfileNotifier extends StateNotifier<ProfileState> {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ProfileNotifier({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        super(const ProfileState());

  /// Load user profile from Firestore
  Future<void> loadProfile(String uid) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final profile = UserProfile.fromFirestore(doc);
        state = state.copyWith(profile: profile, isLoading: false);
      } else {
        state = state.copyWith(
          profile: UserProfile(uid: uid),
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to load profile',
        isLoading: false,
      );
    }
  }

  /// Update profile field - creates document if it doesn't exist
  Future<void> updateProfile({
    String? name,
    String? gender,
    String? bodyType,
    String? skinTone,
    List<String>? styles,
    List<String>? colors,
    List<String>? occasions,
    String? clothingSize,
  }) async {
    final currentProfile = state.profile;
    if (currentProfile == null) return;

    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      final updatedProfile = currentProfile.copyWith(
        name: name ?? currentProfile.name,
        gender: gender ?? currentProfile.gender,
        bodyType: bodyType ?? currentProfile.bodyType,
        skinTone: skinTone ?? currentProfile.skinTone,
        styles: styles ?? currentProfile.styles,
        colors: colors ?? currentProfile.colors,
        occasions: occasions ?? currentProfile.occasions,
        clothingSize: clothingSize ?? currentProfile.clothingSize,
      );

      // Use set with merge to create document if it doesn't exist
      await _firestore.collection('users').doc(currentProfile.uid).set(
        updatedProfile.toFirestore(),
        SetOptions(merge: true),
      );

      state = state.copyWith(profile: updatedProfile, isSaving: false);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to update profile',
        isSaving: false,
      );
    }
  }

  /// Complete onboarding and mark as done
  Future<void> completeOnboarding() async {
    final currentProfile = state.profile;
    if (currentProfile == null) return;

    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      await _firestore.collection('users').doc(currentProfile.uid).set({
        'onboardingCompleted': true,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      state = state.copyWith(
        profile: currentProfile.copyWith(onboardingCompleted: true),
        isSaving: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to complete onboarding',
        isSaving: false,
      );
    }
  }

  /// Upload profile image
  Future<String?> uploadProfileImage(String uid, String imagePath) async {
    try {
      final ref = _storage.ref().child('profile_photos').child('$uid.jpg');
await ref.putFile(
        File(imagePath),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await ref.getDownloadURL();
      
      // Update profile with image URL
      await _firestore.collection('users').doc(uid).update({
        'profileImageUrl': url,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Update local state
      if (state.profile != null) {
        state = state.copyWith(
          profile: state.profile!.copyWith(profileImageUrl: url),
        );
      }

      return url;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to upload image');
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Firebase Auth provider for logout
final authServiceProvider = Provider<auth.FirebaseAuth>((ref) {
  return auth.FirebaseAuth.instance;
});

/// Profile provider
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier();
});
