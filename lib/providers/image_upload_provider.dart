import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ImageUploadNotifier extends StateNotifier<AsyncValue<String>> {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  ImageUploadNotifier() : super(const AsyncValue.data(''));

  Future<void> pickAndUploadImage({
    required bool fromCamera,
    required String category,
    required String color,
    required String style,
  }) async {
    try {
      state = const AsyncValue.loading();

      // Pick image
      final pickedFile = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        state = const AsyncValue.data('');
        return;
      }

      // Upload to Firebase Storage
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      final fileName =
          'wardrobe/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref(fileName);

      final uploadTask = await storageRef.putFile(
        File(pickedFile.path),
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Save wardrobe item to Firestore
      await _firestore.collection('wardrobe_items').add({
        'userId': uid,
        'imageUrl': downloadUrl,
        'category': category,
        'color': color,
        'style': style,
        'createdAt': Timestamp.now(),
      });

      state = AsyncValue.data(downloadUrl);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void reset() {
    state = const AsyncValue.data('');
  }
}

final imageUploadProvider =
    StateNotifierProvider<ImageUploadNotifier, AsyncValue<String>>(
  (ref) => ImageUploadNotifier(),
);
