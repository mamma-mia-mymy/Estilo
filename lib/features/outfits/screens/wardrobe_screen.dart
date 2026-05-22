import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

// ─── Model ───────────────────────────────────────────────────────────

class WardrobeItem {
  final String id;
  final String userId;
  final String imageUrl;
  final String imageBase64;
  final String category;
  final String color;
  final String style;
  final DateTime createdAt;
  final bool isFavorite;

  const WardrobeItem({
    required this.id,
    required this.userId,
    required this.imageUrl,
    this.imageBase64 = '',
    required this.category,
    required this.color,
    required this.style,
    required this.createdAt,
    this.isFavorite = false,
  });

  factory WardrobeItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WardrobeItem(
      id: doc.id,
      userId: data['userId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      imageBase64: data['imageBase64'] ?? '',
      category: data['category'] ?? '',
      color: data['color'] ?? '',
      style: data['style'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isFavorite: data['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'imageUrl': imageUrl,
        'imageBase64': imageBase64,
        'category': category,
        'color': color,
        'style': style,
        'createdAt': Timestamp.fromDate(createdAt),
        'isFavorite': isFavorite,
      };

  WardrobeItem copyWith({
    String? category,
    String? color,
    String? style,
    String? imageUrl,
    String? imageBase64,
    bool? isFavorite,
  }) =>
      WardrobeItem(
        id: id,
        userId: userId,
        imageUrl: imageUrl ?? this.imageUrl,
        imageBase64: imageBase64 ?? this.imageBase64,
        category: category ?? this.category,
        color: color ?? this.color,
        style: style ?? this.style,
        createdAt: createdAt,
        isFavorite: isFavorite ?? this.isFavorite,
      );
}

// ─── Repository ──────────────────────────────────────────────────────

class WardrobeRepository {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Stream<List<WardrobeItem>> watchItems() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    return _firestore
        .collection('wardrobe_items')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((s) {
          final items = s.docs.map(WardrobeItem.fromFirestore).toList();
          // Sort by createdAt in code (no composite index needed)
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items;
        });
  }

  Future<void> updateItem(String id, Map<String, dynamic> data) =>
      _firestore.collection('wardrobe_items').doc(id).update(data);

  Future<void> toggleFavorite(WardrobeItem item) =>
      _firestore.collection('wardrobe_items').doc(item.id).update({
        'isFavorite': !item.isFavorite,
      });

  Future<void> deleteItem(WardrobeItem item) async {
    await _firestore.collection('wardrobe_items').doc(item.id).delete();
    if (item.imageUrl.isNotEmpty) {
      try {
        await _storage.refFromURL(item.imageUrl).delete();
      } catch (_) {}
    }
  }
}

// ─── Providers ───────────────────────────────────────────────────────

final wardrobeRepositoryProvider =
    Provider((_) => WardrobeRepository());

final wardrobeStreamProvider = StreamProvider<List<WardrobeItem>>((ref) {
  return ref.watch(wardrobeRepositoryProvider).watchItems();
});

final wardrobeFilterProvider = StateProvider<String>((ref) => 'All');
final wardrobeSearchProvider = StateProvider<String>((ref) => '');
final showFavoritesOnlyProvider = StateProvider<bool>((ref) => false);
final wardrobeSortProvider = StateProvider<String>((ref) => 'Newest');
final wardrobeViewModeProvider = StateProvider<String>((ref) => 'Grid');

final filteredWardrobeProvider = Provider<AsyncValue<List<WardrobeItem>>>((ref) {
  final items = ref.watch(wardrobeStreamProvider);
  final filter = ref.watch(wardrobeFilterProvider);
  final search = ref.watch(wardrobeSearchProvider).toLowerCase();
  final favoritesOnly = ref.watch(showFavoritesOnlyProvider);
  final sortBy = ref.watch(wardrobeSortProvider);

  return items.whenData((list) {
    var filtered = list.where((item) {
      final matchesFilter = filter == 'All' ||
          item.category.toLowerCase() == filter.toLowerCase() ||
          item.style.toLowerCase() == filter.toLowerCase();
      final matchesSearch = search.isEmpty ||
          item.category.toLowerCase().contains(search) ||
          item.color.toLowerCase().contains(search) ||
          item.style.toLowerCase().contains(search);
      final matchesFavorites = !favoritesOnly || item.isFavorite;
      return matchesFilter && matchesSearch && matchesFavorites;
    }).toList();

    // Apply sorting
    switch (sortBy) {
      case 'Newest':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Oldest':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'Color':
        filtered.sort((a, b) => a.color.compareTo(b.color));
        break;
      case 'Style':
        filtered.sort((a, b) => a.style.compareTo(b.style));
        break;
      case 'Favorites':
        filtered.sort((a, b) => (b.isFavorite ? 1 : 0).compareTo(a.isFavorite ? 1 : 0));
        break;
    }

    return filtered;
  });
});

// ─── Constants ───────────────────────────────────────────────────────

const _bg = Color(0xFFF5F4F2);
const _ink = Color(0xFF1A1814);
const _sand = Color(0xFFC8C4BE);
const _muted = Color(0xFF8A8784);
const _cardBg = Color(0xFFFFFFFF);
const _border = Color(0xFFE2E0DC);
const _borderStrong = Color(0xFFD8D6D2);

const List<String> kCategories = ['Top', 'Bottom', 'Outerwear', 'Footwear', 'Accessory'];
const List<String> kStyles = ['Casual', 'Formal', 'Vintage', 'Streetwear', 'Minimalist'];
const List<String> kColors = [
  'Black', 'White', 'Gray', 'Beige', 'Brown',
  'Navy', 'Blue', 'Green', 'Red', 'Pink', 'Yellow', 'Orange', 'Purple',
];

Widget wardrobeImage({
  required String imageUrl,
  required String imageBase64,
  required Widget fallback,
  BoxFit fit = BoxFit.cover,
}) {
  if (imageBase64.isNotEmpty) {
    try {
      return Image.memory(
        base64Decode(imageBase64),
        fit: fit,
        width: double.infinity,
        height: double.infinity,
      );
    } catch (_) {
      return fallback;
    }
  }

  if (imageUrl.isNotEmpty) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      placeholder: (_, __) => Container(color: _bg),
      errorWidget: (_, __, ___) => fallback,
    );
  }

  return fallback;
}

// ─── Screen ──────────────────────────────────────────────────────────

class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

static const List<String> _filters = [
    'All', 'Formal', 'Everyday', 'Streetwear', 'Vintage', 'Minimalist', 'Casual',
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = ref.watch(filteredWardrobeProvider);
    final activeFilter = ref.watch(wardrobeFilterProvider);
    final viewMode = ref.watch(wardrobeViewModeProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_showSearch) _buildSearchBar(),
            _buildFilterRow(activeFilter),
            if (viewMode == 'Grid') ...[
              _buildStats(filtered),
              Expanded(child: _buildGrid(filtered)),
            ] else ...[
              Expanded(child: _buildCategoryView(filtered)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final showFavorites = ref.watch(showFavoritesOnlyProvider);
    final sortBy = ref.watch(wardrobeSortProvider);
    final viewMode = ref.watch(wardrobeViewModeProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MY CLOSET',
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2.0,
                      color: _muted)),
              const SizedBox(height: 4),
              Text('Wardrobe',
                  style: GoogleFonts.cormorantGaramond(
                      fontSize: 32,
                      fontWeight: FontWeight.w400,
                      color: _ink)),
            ],
          ),
          Row(
            children: [
              _HeaderBtn(
                icon: showFavorites ? Icons.favorite : Icons.favorite_border,
                isActive: showFavorites,
                onTap: () =>
                    ref.read(showFavoritesOnlyProvider.notifier).state =
                        !showFavorites,
              ),
              const SizedBox(width: 8),
              _HeaderBtn(
                icon: _showSearch
                    ? Icons.search_off_outlined
                    : Icons.search_outlined,
                onTap: () {
                  setState(() => _showSearch = !_showSearch);
                  if (!_showSearch) {
                    _searchController.clear();
                    ref.read(wardrobeSearchProvider.notifier).state = '';
                  }
                },
              ),
              const SizedBox(width: 8),
              _HeaderBtn(
                icon: viewMode == 'Grid' ? Icons.grid_3x3 : Icons.category,
                isActive: viewMode == 'Category',
                onTap: () => ref.read(wardrobeViewModeProvider.notifier).state =
                    viewMode == 'Grid' ? 'Category' : 'Grid',
              ),
              const SizedBox(width: 8),
              _SortBtn(
                currentSort: sortBy,
                onSortChanged: (sort) =>
                    ref.read(wardrobeSortProvider.notifier).state = sort,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
            color: _cardBg, border: Border.all(color: _border, width: 0.5)),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(Icons.search, size: 16, color: _muted),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (v) =>
                    ref.read(wardrobeSearchProvider.notifier).state = v,
                style: GoogleFonts.inter(fontSize: 13, color: _ink),
                decoration: InputDecoration(
                  hintText: 'Search by color, style, category...',
                  hintStyle:
                      GoogleFonts.inter(fontSize: 13, color: _muted),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow(String active) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: _filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final f = _filters[i];
            final isActive = active == f;
            return GestureDetector(
              onTap: () =>
                  ref.read(wardrobeFilterProvider.notifier).state = f,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? _ink : _cardBg,
                  border: Border.all(
                      color: isActive ? _ink : _border,
                      width: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(f.toUpperCase(),
                    style: GoogleFonts.inter(
                        fontSize: 9,
                        letterSpacing: 1.3,
                        fontWeight: FontWeight.w500,
                        color: isActive ? _sand : _muted)),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStats(AsyncValue<List<WardrobeItem>> filtered) {
    return filtered.when(
      data: (items) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 2),
        child: Text('${items.length} item${items.length != 1 ? 's' : ''}',
            style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.6,
                color: _muted)),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildGrid(AsyncValue<List<WardrobeItem>> filtered) {
    return filtered.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: _ink, strokeWidth: 1)),
      error: (e, _) => Center(
          child: Text('Error loading wardrobe',
              style: GoogleFonts.inter(color: _muted))),
      data: (items) {
        if (items.isEmpty) return _buildEmptyState();
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 1,
            crossAxisSpacing: 1,
            childAspectRatio: 0.72,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => _WardrobeCard(
            item: items[i],
            onEdit: () => _showEditSheet(items[i]),
            onDelete: () => _confirmDelete(items[i]),
          ),
        );
      },
    );
  }

  Widget _buildCategoryView(AsyncValue<List<WardrobeItem>> filtered) {
    return filtered.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: _ink, strokeWidth: 1)),
      error: (e, _) => Center(
          child: Text('Error loading wardrobe',
              style: GoogleFonts.inter(color: _muted))),
      data: (items) {
        if (items.isEmpty) return _buildEmptyState();
        
        // Group items by category
        final grouped = <String, List<WardrobeItem>>{};
        for (var item in items) {
          grouped.putIfAbsent(item.category, () => []).add(item);
        }
        
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          children: grouped.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.key.toUpperCase(),
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.6,
                        color: _muted)),
                const SizedBox(height: 12),
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 1,
                    crossAxisSpacing: 1,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: entry.value.length,
                  itemBuilder: (_, i) => _WardrobeCard(
                    item: entry.value[i],
                    onEdit: () => _showEditSheet(entry.value[i]),
                    onDelete: () => _confirmDelete(entry.value[i]),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFAF9F8),
                border: Border.all(color: _border, width: 0.5),
              ),
              child: const Center(
                  child: Icon(Icons.checkroom_outlined,
                      size: 36, color: _muted)),
            ),
            const SizedBox(height: 24),
            Text('Your closet is empty.',
                style: GoogleFonts.cormorantGaramond(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    color: _ink)),
            const SizedBox(height: 12),
            Text(
                'Upload your first clothing item to start building your digital wardrobe.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                    color: _muted,
                    height: 1.6)),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => context.push('/add-wardrobe-item'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: _ink,
                  border: Border.all(color: _ink, width: 0.5),
                ),
                child: Text('ADD ITEM',
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.8,
                        color: _sand)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSheet(WardrobeItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditItemSheet(item: item),
    );
  }

  void _confirmDelete(WardrobeItem item) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: _bg,
        shape: const RoundedRectangleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('REMOVE ITEM',
                  style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.8,
                      color: _muted)),
              const SizedBox(height: 10),
              Text('Delete this piece?',
                  style: GoogleFonts.cormorantGaramond(
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      color: _ink)),
              const SizedBox(height: 8),
              Text(
                  'This will permanently remove the item and its image from your wardrobe.',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: _muted,
                      height: 1.5)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: _borderStrong, width: 0.5)),
                        child: Center(
                          child: Text('CANCEL',
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  letterSpacing: 1.6,
                                  color: _muted)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        await ref
                            .read(wardrobeRepositoryProvider)
                            .deleteItem(item);
                      },
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        color: _ink,
                        child: Center(
                          child: Text('DELETE',
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  letterSpacing: 1.6,
                                  color: _sand)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Wardrobe Card ───────────────────────────────────────────────────

class _WardrobeCard extends ConsumerWidget {
  final WardrobeItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _WardrobeCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onLongPress: () => _showActions(context),
      child: Container(
        color: _cardBg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: wardrobeImage(
                      imageUrl: item.imageUrl,
                      imageBase64: item.imageBase64,
                      fallback: Container(
                        color: _bg,
                        child: const Center(
                          child: Icon(Icons.checkroom_outlined,
                              size: 28, color: _muted),
                        ),
                      ),
                    ),
                  ),
                  // Favorite heart button
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: () => ref
                          .read(wardrobeRepositoryProvider)
                          .toggleFavorite(item),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _cardBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 14,
                          color: item.isFavorite
                              ? const Color(0xFFD64545)
                              : _muted,
                        ),
                      ),
                    ),
                  ),
                  // Edit/Delete buttons
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        _MiniBtn(
                            icon: Icons.edit_outlined, onTap: onEdit),
                        const SizedBox(width: 4),
                        _MiniBtn(
                            icon: Icons.delete_outline,
                            onTap: onDelete),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.category.toUpperCase(),
                      style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.3,
                          color: _muted)),
                  const SizedBox(height: 3),
                  Text('${item.color}',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: _ink)),
                  const SizedBox(height: 2),
                  Text(item.style,
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w300,
                          color: _muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        color: _bg,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
                child: Container(
                    width: 32, height: 2, color: _borderStrong)),
            const SizedBox(height: 20),
            _ActionTile(
                icon: Icons.edit_outlined,
                label: 'Edit Item',
                onTap: () {
                  Navigator.pop(context);
                  onEdit();
                }),
            const SizedBox(height: 10),
            _ActionTile(
                icon: Icons.delete_outline,
                label: 'Delete Item',
                onTap: () {
                  Navigator.pop(context);
                  onDelete();
                }),
          ],
        ),
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MiniBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        color: _ink,
        child: Icon(icon, size: 13, color: _sand),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: _cardBg, border: Border.all(color: _border, width: 0.5)),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              color: _bg,
              child: Center(child: Icon(icon, size: 16, color: _ink)),
            ),
            const SizedBox(width: 14),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                    color: _ink)),
          ],
        ),
      ),
    );
  }
}

class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  const _HeaderBtn({required this.icon, required this.onTap, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
            color: isActive ? _ink : _cardBg,
            border: Border.all(
                color: isActive ? _ink : _border, width: 0.5)),
        child: Icon(icon, size: 18, color: isActive ? _sand : _ink),
      ),
    );
  }
}

class _SortBtn extends StatelessWidget {
  final String currentSort;
  final Function(String) onSortChanged;
  const _SortBtn({required this.currentSort, required this.onSortChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSortChanged,
      itemBuilder: (BuildContext context) => [
        'Newest', 'Oldest', 'Color', 'Style', 'Favorites'
      ].map((String choice) {
        return PopupMenuItem<String>(
          value: choice,
          child: Row(
            children: [
              if (choice == currentSort)
                const Icon(Icons.check, size: 16, color: _ink)
              else
                const SizedBox(width: 16),
              const SizedBox(width: 8),
              Text(choice, style: GoogleFonts.inter(fontSize: 12, color: _ink)),
            ],
          ),
        );
      }).toList(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
            color: _cardBg, border: Border.all(color: _border, width: 0.5)),
        child: const Icon(Icons.tune_outlined, size: 18, color: _ink),
      ),
    );
  }
}

// ─── Edit Item Sheet ─────────────────────────────────────────────────

class _EditItemSheet extends ConsumerStatefulWidget {
  final WardrobeItem item;
  const _EditItemSheet({required this.item});

  @override
  ConsumerState<_EditItemSheet> createState() => _EditItemSheetState();
}

class _EditItemSheetState extends ConsumerState<_EditItemSheet> {
  late String _category;
  late String _color;
  late String _style;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _category = widget.item.category;
    _color = widget.item.color;
    _style = widget.item.style;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: _bg),
      padding: EdgeInsets.fromLTRB(
          24, 28, 24, MediaQuery.of(context).viewInsets.bottom + 40),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
                child: Container(
                    width: 32, height: 2, color: _borderStrong,
                    margin: const EdgeInsets.only(bottom: 24))),
            Text('EDIT ITEM',
                style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.8,
                    color: _muted)),
            const SizedBox(height: 8),
            Text('Update piece.',
                style: GoogleFonts.cormorantGaramond(
                    fontSize: 26, fontWeight: FontWeight.w400, color: _ink)),
            const SizedBox(height: 24),

            // Category
            _SheetLabel('CATEGORY'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kCategories.map((c) {
                return _SelectChip(
                  label: c,
                  selected: _category == c,
                  onTap: () => setState(() => _category = c),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),
            _SheetLabel('COLOUR'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kColors.map((c) {
                return _SelectChip(
                  label: c,
                  selected: _color == c,
                  onTap: () => setState(() => _color = c),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),
            _SheetLabel('STYLE'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kStyles.map((s) {
                return _SelectChip(
                  label: s,
                  selected: _style == s,
                  onTap: () => setState(() => _style = s),
                );
              }).toList(),
            ),

            const SizedBox(height: 28),
            GestureDetector(
              onTap: _saving ? null : _save,
              child: Container(
                width: double.infinity,
                color: _ink,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 1, color: _sand))
                      : Text('SAVE CHANGES',
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 2.0,
                              color: _sand)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(wardrobeRepositoryProvider).updateItem(widget.item.id, {
      'category': _category,
      'color': _color,
      'style': _style,
    });
    if (mounted) Navigator.pop(context);
  }
}

// ─── Upload Item Sheet ────────────────────────────────────────────────

class UploadItemSheet extends ConsumerStatefulWidget {
  const UploadItemSheet({super.key});

  @override
  ConsumerState<UploadItemSheet> createState() => _UploadItemSheetState();
}

class _UploadItemSheetState extends ConsumerState<UploadItemSheet> {
  Uint8List? _imageBytes;
  String? _category;
  String? _color;
  String? _style;
  bool _uploading = false;
  String? _error;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(
      source: source,
      imageQuality: 55,
      maxWidth: 700,
      maxHeight: 700,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  bool get _isValid =>
      _imageBytes != null &&
      _category != null &&
      _color != null &&
      _style != null;

  Future<void> _upload() async {
    if (!_isValid) {
      setState(() => _error = 'Please complete all fields before saving.');
      return;
    }
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      if (_imageBytes!.lengthInBytes > 750 * 1024) {
        throw Exception('Image is too large. Please choose a smaller photo.');
      }
      
      // Upload image to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('wardrobe_items')
          .child(uid)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = await storageRef.putData(_imageBytes!);
      final imageUrl = await uploadTask.ref.getDownloadURL();
      
      print('🖼️ Image uploaded to Storage: $imageUrl');

      final imageBase64 = base64Encode(_imageBytes!);

      await FirebaseFirestore.instance.collection('wardrobe_items').add({
        'userId': uid,
        'imageUrl': imageUrl,  // ✅ Now has the Storage URL
        'imageBase64': imageBase64,
        'category': _category,
        'color': _color,
        'style': _style,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = 'Upload failed. Please try again.';
        _uploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: _bg),
      padding: EdgeInsets.fromLTRB(
          24, 28, 24, MediaQuery.of(context).viewInsets.bottom + 40),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
                child: Container(
                    width: 32,
                    height: 2,
                    color: _borderStrong,
                    margin: const EdgeInsets.only(bottom: 24))),
            Text('ADD TO WARDROBE',
                style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.8,
                    color: _muted)),
            const SizedBox(height: 8),
            Text('Upload a piece.',
                style: GoogleFonts.cormorantGaramond(
                    fontSize: 26,
                    fontWeight: FontWeight.w400,
                    color: _ink)),

            const SizedBox(height: 20),

            // Image picker
            GestureDetector(
              onTap: () => _pickImage(ImageSource.gallery),
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                    color: _cardBg,
                    border: Border.all(color: _border, width: 0.5)),
                child: _imageBytes != null
                    ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt_outlined,
                              size: 28, color: _muted),
                          const SizedBox(height: 8),
                          Text('TAP TO SELECT IMAGE',
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  letterSpacing: 1.4,
                                  color: _muted)),
                        ],
                      ),
              ),
            ),

            if (_imageBytes != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    _SourceBtn(
                        icon: Icons.camera_alt_outlined,
                        label: 'Camera',
                        onTap: () => _pickImage(ImageSource.camera)),
                    const SizedBox(width: 8),
                    _SourceBtn(
                        icon: Icons.photo_library_outlined,
                        label: 'Gallery',
                        onTap: () => _pickImage(ImageSource.gallery)),
                  ],
                ),
              ),

            const SizedBox(height: 20),
            _SheetLabel('CATEGORY'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kCategories.map((c) => _SelectChip(
                    label: c,
                    selected: _category == c,
                    onTap: () => setState(() => _category = c),
                  )).toList(),
            ),

            const SizedBox(height: 18),
            _SheetLabel('COLOUR'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kColors.map((c) => _SelectChip(
                    label: c,
                    selected: _color == c,
                    onTap: () => setState(() => _color = c),
                  )).toList(),
            ),

            const SizedBox(height: 18),
            _SheetLabel('STYLE'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kStyles.map((s) => _SelectChip(
                    label: s,
                    selected: _style == s,
                    onTap: () => setState(() => _style = s),
                  )).toList(),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFFAA4444),
                      fontWeight: FontWeight.w300)),
            ],

            const SizedBox(height: 24),
            GestureDetector(
              onTap: _uploading ? null : _upload,
              child: Container(
                width: double.infinity,
                color: _isValid ? _ink : const Color(0xFF3A3834),
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: _uploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 1, color: _sand))
                      : Text('SAVE TO WARDROBE',
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 2.0,
                              color: _sand)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared sheet widgets ─────────────────────────────────────────────

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.8,
          color: _muted));
}

class _SelectChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SelectChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF252320) : _cardBg,
          border: Border.all(
              color: selected ? _ink : _borderStrong, width: 0.5),
        ),
        child: Text(label.toUpperCase(),
            style: GoogleFonts.inter(
                fontSize: 10,
                letterSpacing: 1.1,
                color: selected ? _sand : _muted)),
      ),
    );
  }
}

class _SourceBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: _cardBg,
            border: Border.all(color: _border, width: 0.5)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: _ink),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w300,
                    color: _ink)),
          ],
        ),
      ),
    );
  }
}
