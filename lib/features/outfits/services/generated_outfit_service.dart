import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/generated_outfit_model.dart';

class GeneratedOutfitService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  
  static const String _collectionName = 'generated_outfits';

  /// Save a generated outfit to Firestore
  Future<String> saveOutfit({
    required String topId,
    required String bottomId,
    required String topImageUrl,
    required String bottomImageUrl,
    required double score,
    required String explanation,
    required double temperature,
    required String weatherCondition,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final outfit = GeneratedOutfit(
      id: '', // Will be set by Firestore
      userId: userId,
      topId: topId,
      bottomId: bottomId,
      topImageUrl: topImageUrl,
      bottomImageUrl: bottomImageUrl,
      score: score,
      explanation: explanation,
      temperature: temperature,
      weatherCondition: weatherCondition,
      createdAt: DateTime.now(),
    );

    try {
      final docRef = await _firestore
          .collection(_collectionName)
          .add(outfit.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save outfit: $e');
    }
  }

  /// Get all generated outfits for the current user, ordered by recent
  Stream<List<GeneratedOutfit>> getUserOutfitsStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return const Stream.empty();

    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GeneratedOutfit.fromFirestore(doc))
            .toList());
  }

  /// Get saved/favorited outfits
  Stream<List<GeneratedOutfit>> getSavedOutfitsStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return const Stream.empty();

    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .where('isFavorited', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GeneratedOutfit.fromFirestore(doc))
            .toList());
  }

  /// Get a single outfit by ID
  Future<GeneratedOutfit?> getOutfitById(String outfitId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(outfitId)
          .get();
      
      if (!doc.exists) return null;
      return GeneratedOutfit.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch outfit: $e');
    }
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String outfitId, bool isFavorite) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(outfitId)
          .update({'isFavorited': isFavorite});
    } catch (e) {
      throw Exception('Failed to update favorite status: $e');
    }
  }

  /// Delete an outfit
  Future<void> deleteOutfit(String outfitId) async {
    try {
      await _firestore.collection(_collectionName).doc(outfitId).delete();
    } catch (e) {
      throw Exception('Failed to delete outfit: $e');
    }
  }

  /// Get recent outfits (last 5)
  Stream<List<GeneratedOutfit>> getRecentOutfitsStream({int limit = 5}) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return const Stream.empty();

    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GeneratedOutfit.fromFirestore(doc))
            .toList());
  }
}
