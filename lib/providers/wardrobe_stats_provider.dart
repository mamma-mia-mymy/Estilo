import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/outfits/screens/wardrobe_screen.dart';

class WardrobeStats {
  final int totalCount;
  final int topsCount;
  final int bottomsCount;
  final WardrobeItem? recentItem;

  const WardrobeStats({
    required this.totalCount,
    required this.topsCount,
    required this.bottomsCount,
    this.recentItem,
  });
}

class WardrobeStatsNotifier extends StateNotifier<AsyncValue<WardrobeStats>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  WardrobeStatsNotifier() : super(const AsyncValue.loading()) {
    _loadStats();
  }

  void _loadStats() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      state = const AsyncValue.data(
        WardrobeStats(
          totalCount: 0,
          topsCount: 0,
          bottomsCount: 0,
        ),
      );
      return;
    }

    _firestore
        .collection('wardrobe_items')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
      try {
        final items = snapshot.docs.map(WardrobeItem.fromFirestore).toList();
        
        // Sort by createdAt in code instead of using orderBy (no index needed)
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        final totalCount = items.length;
        final topsCount =
            items.where((item) => item.category.toLowerCase() == 'top').length;
        final bottomsCount = items
            .where((item) => item.category.toLowerCase() == 'bottom')
            .length;
        final recentItem = items.isNotEmpty ? items.first : null;

        final stats = WardrobeStats(
          totalCount: totalCount,
          topsCount: topsCount,
          bottomsCount: bottomsCount,
          recentItem: recentItem,
        );

        state = AsyncValue.data(stats);
      } catch (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      }
    });
  }
}

final wardrobeStatsProvider =
    StateNotifierProvider<WardrobeStatsNotifier, AsyncValue<WardrobeStats>>(
  (ref) => WardrobeStatsNotifier(),
);
