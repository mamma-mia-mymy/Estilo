import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../providers/generated_outfit_provider.dart';
import '../widgets/outfit_card.dart';

class OutfitsScreen extends ConsumerStatefulWidget {
  const OutfitsScreen({super.key});

  @override
  ConsumerState<OutfitsScreen> createState() => _OutfitsScreenState();
}

class _OutfitsScreenState extends ConsumerState<OutfitsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Outfits',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1A1814),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1A1814),
          tabs: const [
            Tab(text: 'Recent'),
            Tab(text: 'Saved'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Recent Outfits Tab
          _buildRecentTab(),
          // Saved Outfits Tab
          _buildSavedTab(),
        ],
      ),
    );
  }

  Widget _buildRecentTab() {
    final outfitsAsync = ref.watch(recentOutfitsProvider);

    return outfitsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (err, stack) => Center(
        child: Text('Error: $err'),
      ),
      data: (outfits) {
        if (outfits.isEmpty) {
          return _buildEmptyState();
        }
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: outfits.length,
              itemBuilder: (context, index) {
                return OutfitCard(
                  outfit: outfits[index],
                  onTap: () => context.push('/outfits/${outfits[index].id}'),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavedTab() {
    final outfitsAsync = ref.watch(savedOutfitsProvider);

    return outfitsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (err, stack) => Center(
        child: Text('Error: $err'),
      ),
      data: (outfits) {
        if (outfits.isEmpty) {
          return _buildEmptySavedState();
        }
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: outfits.length,
              itemBuilder: (context, index) {
                return OutfitCard(
                  outfit: outfits[index],
                  onTap: () => context.push('/outfits/${outfits[index].id}'),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.checkroom_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Generate your first outfit.',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/mix-match'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1814),
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
              ),
            ),
            child: Text(
              'Go to Mix & Match',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySavedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No saved outfits yet.',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Favorite outfits will appear here.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
