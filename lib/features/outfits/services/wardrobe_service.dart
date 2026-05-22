import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wardrobe_item_model.dart';

class WardrobeService {
  final FirebaseFirestore _firestore;

  WardrobeService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetch all wardrobe items for a user
  Future<List<WardrobeItemModel>> getWardrobeItems(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('wardrobe_items')
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => WardrobeItemModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw WardrobeServiceException('Failed to fetch wardrobe items: $e');
    }
  }

  /// Fetch only tops
  Future<List<WardrobeItemModel>> getTops(String userId) async {
    final items = await getWardrobeItems(userId);
    return items.where((item) => item.category == WardrobeCategory.top).toList();
  }

  /// Fetch only bottoms
  Future<List<WardrobeItemModel>> getBottoms(String userId) async {
    final items = await getWardrobeItems(userId);
    return items.where((item) => item.category == WardrobeCategory.bottom).toList();
  }

  /// Add a new wardrobe item
  Future<WardrobeItemModel> addWardrobeItem({
    required String userId,
    required String imageUrl,
    String imageBase64 = '',
    required WardrobeCategory category,
    required String color,
    required WardrobeStyle style,
  }) async {
    try {
      final docRef = _firestore.collection('wardrobe_items').doc();
      final item = WardrobeItemModel(
        id: docRef.id,
        userId: userId,
        imageUrl: imageUrl,
        imageBase64: imageBase64,
        category: category,
        color: color,
        style: style,
        createdAt: DateTime.now(),
      );

      await docRef.set(item.toFirestore());
      return item;
    } catch (e) {
      throw WardrobeServiceException('Failed to add wardrobe item: $e');
    }
  }

  /// Delete a wardrobe item
  Future<void> deleteWardrobeItem(String itemId) async {
    try {
      await _firestore.collection('wardrobe_items').doc(itemId).delete();
    } catch (e) {
      throw WardrobeServiceException('Failed to delete wardrobe item: $e');
    }
  }

  /// Get wardrobe item count
  Future<int> getWardrobeItemCount(String userId) async {
    final items = await getWardrobeItems(userId);
    return items.length;
  }

  /// Get tops count
  Future<int> getTopsCount(String userId) async {
    final tops = await getTops(userId);
    return tops.length;
  }

  /// Get bottoms count
  Future<int> getBottomsCount(String userId) async {
    final bottoms = await getBottoms(userId);
    return bottoms.length;
  }

  /// Stream wardrobe items for real-time updates
  Stream<List<WardrobeItemModel>> watchWardrobeItems(String userId) {
    return _firestore
        .collection('wardrobe_items')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WardrobeItemModel.fromFirestore(doc))
            .toList());
  }
}

class WardrobeServiceException implements Exception {
  final String message;
  WardrobeServiceException(this.message);

  @override
  String toString() => message;
}
