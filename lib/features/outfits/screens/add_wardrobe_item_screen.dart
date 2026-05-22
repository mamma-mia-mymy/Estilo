import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const List<String> _categories = [
  'Top', 'Bottom', 'Outerwear', 'Footwear', 'Accessory'
];
const List<String> _colors = [
  'Black', 'White', 'Gray', 'Beige', 'Brown',
  'Navy', 'Blue', 'Green', 'Red', 'Pink',
  'Yellow', 'Orange', 'Purple', 'Cream', 'Olive',
];
const List<String> _styles = [
  'Casual', 'Formal', 'Vintage', 'Streetwear', 'Minimalist',
];

class AddWardrobeItemScreen extends ConsumerStatefulWidget {
  const AddWardrobeItemScreen({super.key});

  @override
  ConsumerState<AddWardrobeItemScreen> createState() =>
      _AddWardrobeItemScreenState();
}

class _AddWardrobeItemScreenState
    extends ConsumerState<AddWardrobeItemScreen> {
  Uint8List? _imageBytes;
  String? _category;
  String? _color;
  String? _style;
  bool _uploading = false;
  String? _error;

  static const Color _bg          = Color(0xFFF5F4F2);
  static const Color _ink         = Color(0xFF1A1814);
  static const Color _sand        = Color(0xFFC8C4BE);
  static const Color _muted       = Color(0xFF8A8784);
  static const Color _cardBg      = Color(0xFFFFFFFF);
  static const Color _border      = Color(0xFFE2E0DC);
  static const Color _borderStrong = Color(0xFFD8D6D2);
  static const Color _disabled    = Color(0xFFD8D6D2);

  // ── All functionality unchanged ───────────────────────────────────

  void _returnToPreviousScreen() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 55,
        maxWidth: 700,
        maxHeight: 700,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _error = null;
        });
      }
    } catch (e) {
      setState(() => _error = 'Failed to pick image');
    }
  }

  bool get _isValid =>
      _imageBytes != null &&
      _category != null &&
      _color != null &&
      _style != null;

  // Count how many of the 4 required fields are filled
  int get _filledCount {
    int count = 0;
    if (_imageBytes != null) count++;
    if (_category != null) count++;
    if (_color != null) count++;
    if (_style != null) count++;
    return count;
  }

  Future<void> _uploadToFirebase() async {
    if (!_isValid) {
      setState(
          () => _error = 'Please complete all fields before saving.');
      return;
    }
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() {
          _uploading = false;
          _error = 'User not authenticated. Please log in again.';
        });
        return;
      }
      debugPrint('=== WARDROBE UPLOAD DEBUG ===');
      debugPrint('UID: $uid');
      debugPrint('Image size: ${_imageBytes?.lengthInBytes} bytes');
      debugPrint('Category: $_category, Color: $_color, Style: $_style');
      if (_imageBytes!.lengthInBytes > 750 * 1024) {
        throw Exception('Image is too large. Please choose a smaller photo.');
      }
      final imageBase64 = base64Encode(_imageBytes!);
      debugPrint('Saving wardrobe item directly to Firestore...');
      await FirebaseFirestore.instance
          .collection('wardrobe_items')
          .add({
            'userId':    uid,
            'imageUrl':  '',
            'imageBase64': imageBase64,
            'category':  _category,
            'color':     _color,
            'style':     _style,
            'isFavorite': false,
            'createdAt': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 15),
              onTimeout: () => throw TimeoutException(
                  'Firestore write timed out.'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item added to wardrobe!',
                style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: _ink,
            duration: const Duration(seconds: 2),
          ),
        );
        _returnToPreviousScreen();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploading = false;
          _error = 'Failed to upload item: ${e.toString()}';
        });
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageHead(),
                    _buildPhotoSection(),
                    _buildDivider(),
                    _buildCategorySection(),
                    _buildColorSection(),
                    _buildStyleSection(),
                    _buildProgressDots(),
                    _buildDivider(),
                    _buildTipStrip(),
                    if (_error != null) _buildError(),
                    _buildSaveButton(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _returnToPreviousScreen,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: _cardBg,
                  border: Border.all(color: _borderStrong, width: 0.5)),
              child: const Icon(Icons.arrow_back, size: 16, color: _ink),
            ),
          ),
          Text('ADD TO WARDROBE',
              style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2.0,
                  color: _muted)),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  // ── Page head ─────────────────────────────────────────────────────

  Widget _buildPageHead() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NEW PIECE',
              style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2.0,
                  color: _muted)),
          const SizedBox(height: 8),
          Text('Upload an\nitem.',
              style: GoogleFonts.cormorantGaramond(
                  fontSize: 36,
                  fontWeight: FontWeight.w400,
                  color: _ink,
                  height: 1.0)),
        ],
      ),
    );
  }

  // ── Photo section ─────────────────────────────────────────────────

  Widget _buildPhotoSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo frame
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
                color: _cardBg,
                border: Border.all(
                    color: _imageBytes != null ? _ink : _border,
                    width: 0.5)),
            child: _imageBytes != null
                ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_photo_alternate_outlined,
                          size: 32, color: Color(0xFFD8D6D2)),
                      const SizedBox(height: 10),
                      Text('TAP TO ADD A PHOTO',
                          style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 1.4,
                              color: const Color(0xFFC8C4BE))),
                    ],
                  ),
          ),

          const SizedBox(height: 10),

          // Camera / Gallery buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickImage(ImageSource.camera),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                        color: _cardBg,
                        border: Border.all(color: _border, width: 0.5)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt_outlined,
                            size: 14, color: Color(0xFF4A4844)),
                        const SizedBox(width: 6),
                        Text('CAMERA',
                            style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.4,
                                color: const Color(0xFF4A4844))),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickImage(ImageSource.gallery),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                        color: _cardBg,
                        border: Border.all(color: _border, width: 0.5)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.photo_library_outlined,
                            size: 14, color: Color(0xFF4A4844)),
                        const SizedBox(width: 6),
                        Text('GALLERY',
                            style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.4,
                                color: const Color(0xFF4A4844))),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Category ──────────────────────────────────────────────────────

  Widget _buildCategorySection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('CATEGORY'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final sel = _category == cat;
              return GestureDetector(
                onTap: () => setState(() => _category = cat),
                child: _Chip(label: cat, selected: sel),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Colour ────────────────────────────────────────────────────────

  Widget _buildColorSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('COLOUR'),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _colors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final color = _colors[i];
                final sel = _color == color;
                return GestureDetector(
                  onTap: () => setState(() => _color = color),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? _ink : _cardBg,
                      border: Border.all(
                          color: sel ? _ink : _border, width: 0.5),
                    ),
                    child: Center(
                      child: Text(color,
                          style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.2,
                              color: sel ? _sand : _muted)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Style ─────────────────────────────────────────────────────────

  Widget _buildStyleSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('STYLE AESTHETIC'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _styles.map((style) {
              final sel = _style == style;
              return GestureDetector(
                onTap: () => setState(() => _style = style),
                child: _Chip(label: style, selected: sel),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Progress dots ─────────────────────────────────────────────────

  Widget _buildProgressDots() {
    final filled = _filledCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        children: [
          Text('FIELDS',
              style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.4,
                  color: _muted)),
          const SizedBox(width: 10),
          ...List.generate(4, (i) {
            final isFilled = i < filled;
            return Container(
              margin: const EdgeInsets.only(right: 6),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled ? _ink : _border,
              ),
            );
          }),
          const SizedBox(width: 4),
          Text('$filled / 4',
              style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w300,
                  color: _muted)),
        ],
      ),
    );
  }

  // ── Tip strip ─────────────────────────────────────────────────────

  Widget _buildTipStrip() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: _ink, width: 1.5),
        ),
      ),
      child: Text(
          '"Lay the garment flat on a neutral surface for the cleanest photo."',
          style: GoogleFonts.cormorantGaramond(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
              color: _ink,
              height: 1.4)),
    );
  }

  // ── Error ─────────────────────────────────────────────────────────

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          border: Border.all(color: const Color(0xFFFFCDD2), width: 0.5)),
      child: Text(_error!,
          style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w300,
              color: const Color(0xFFC62828))),
    );
  }

  // ── Save button ───────────────────────────────────────────────────

  Widget _buildSaveButton() {
    final active = !_uploading && _isValid;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GestureDetector(
        onTap: active ? _uploadToFirebase : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          color: active ? _ink : _disabled,
          child: Center(
            child: _uploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(_sand)))
                : Text('SAVE TO WARDROBE',
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2.2,
                        color: active ? _sand : _muted)),
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────

  Widget _fieldLabel(String text) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w500,
          letterSpacing: 2.0,
          color: _muted));

  Widget _buildDivider() => Container(
      height: 0.5,
      color: _border,
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 0));
}

// ── Shared chip ───────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  const _Chip({required this.label, required this.selected});

  static const Color _ink    = Color(0xFF1A1814);
  static const Color _sand   = Color(0xFFC8C4BE);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE2E0DC);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? _ink : _cardBg,
        border: Border.all(
            color: selected ? _ink : _border, width: 0.5),
      ),
      child: Text(label.toUpperCase(),
          style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.4,
              color: selected ? _sand : const Color(0xFF4A4844))),
    );
  }
}
