import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const List<String> _categories = ['Top', 'Bottom'];
const List<String> _colors = [
  'Black', 'White', 'Gray', 'Beige', 'Brown',
  'Navy', 'Blue', 'Green', 'Red', 'Pink',
  'Yellow', 'Orange', 'Purple', 'Cream', 'Olive',
];
const List<String> _styles = [
  'Casual', 'Formal', 'Vintage', 'Streetwear', 'Minimalist',
];

class UploadPhotoScreen extends ConsumerStatefulWidget {
  const UploadPhotoScreen({super.key});

  @override
  ConsumerState<UploadPhotoScreen> createState() => _UploadPhotoScreenState();
}

class _UploadPhotoScreenState extends ConsumerState<UploadPhotoScreen> {
  Uint8List? _imageBytes;
  String? _category;
  String? _color;
  String? _style;
  bool _uploading = false;
  String? _error;

  static const Color _bg = Color(0xFFF5F4F2);
  static const Color _ink = Color(0xFF1A1814);
  static const Color _sand = Color(0xFFC8C4BE);
  static const Color _muted = Color(0xFF8A8784);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE2E0DC);

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
      _imageBytes != null && _category != null && _color != null && _style != null;

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
        if (mounted) {
          setState(() {
            _uploading = false;
            _error = 'User not authenticated. Please log in again.';
          });
        }
        return;
      }

      print('=== UPLOAD DEBUG ===');
      print('UID: $uid');
      print('Image size: ${_imageBytes?.lengthInBytes} bytes');
      print('Category: $_category, Color: $_color, Style: $_style');

      if (_imageBytes!.lengthInBytes > 750 * 1024) {
        throw Exception('Image is too large. Please choose a smaller photo.');
      }
      final imageBase64 = base64Encode(_imageBytes!);
      print('Saving wardrobe item directly to Firestore...');
      {
        final docRef = await FirebaseFirestore.instance
            .collection('wardrobe_items')
            .add({
              'userId': uid,
              'imageUrl': '',
              'imageBase64': imageBase64,
              'category': _category,
              'color': _color,
              'style': _style,
              'createdAt': FieldValue.serverTimestamp(),
            })
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw TimeoutException(
                'Firestore write timed out after Storage upload completed.',
              ),
            );
        print('Firestore write complete: ${docRef.id}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Item added to wardrobe!',
                style: GoogleFonts.inter(fontSize: 12),
              ),
              backgroundColor: _ink,
              duration: const Duration(seconds: 2),
            ),
          );
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) {
            setState(() => _uploading = false);
            context.pop();
          }
        }
        return;
      }
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('wardrobe_items')
          .child(uid)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = storageRef.putData(
        _imageBytes!,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      await uploadTask;
      print('✓ Storage upload complete');

      final imageUrl = await storageRef.getDownloadURL();
      print('✓ Got download URL: $imageUrl');

      // Save metadata to Firestore
      print('Starting Firestore write...');
      final docRef = await FirebaseFirestore.instance.collection('wardrobe_items').add({
        'userId': uid,
        'imageUrl': imageUrl,
        'category': _category,
        'color': _color,
        'style': _style,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✓ Firestore write complete: ${docRef.id}');

      // Show success and pop only after everything is confirmed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item added to wardrobe!',
                style: GoogleFonts.inter(fontSize: 12)),
            backgroundColor: _ink,
            duration: const Duration(seconds: 2),
          ),
        );
        // Give the snackbar time to be processed before popping
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          setState(() => _uploading = false);
          context.pop();
        }
      }
    } catch (e, st) {
      print('❌ UPLOAD ERROR: $e');
      print('Stack trace: $st');
      if (mounted) {
        setState(() {
          _error = 'Upload failed: ${e.toString()}';
          _uploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Image Picker ──
                    GestureDetector(
                      onTap: () => _pickImage(ImageSource.gallery),
                      child: Container(
                        width: double.infinity,
                        height: 240,
                        decoration: BoxDecoration(
                          color: _cardBg,
                          border: Border.all(color: _border, width: 0.5),
                        ),
                        child: _imageBytes != null
                            ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                            : Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.camera_alt_outlined,
                                      size: 32, color: _muted),
                                  const SizedBox(height: 12),
                                  Text('TAP TO SELECT IMAGE',
                                      style: GoogleFonts.inter(
                                          fontSize: 11,
                                          letterSpacing: 1.4,
                                          color: _muted,
                                          fontWeight:
                                              FontWeight.w300)),
                                ],
                              ),
                      ),
                    ),

                    if (_imageBytes != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: _ImageSourceBtn(
                                icon: Icons.camera_alt_outlined,
                                label: 'Camera',
                                onTap: () =>
                                    _pickImage(ImageSource.camera),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ImageSourceBtn(
                                icon: Icons.photo_library_outlined,
                                label: 'Gallery',
                                onTap: () =>
                                    _pickImage(ImageSource.gallery),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 28),

                    // ── Category ──
                    _buildLabel('CATEGORY'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        final selected = _category == cat;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _category = cat),
                          child: _SelectChip(
                            label: cat,
                            selected: selected,
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // ── Color ──
                    _buildLabel('COLOR'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _colors.map((col) {
                        final selected = _color == col;
                        return GestureDetector(
                          onTap: () => setState(() => _color = col),
                          child: _SelectChip(
                            label: col,
                            selected: selected,
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // ── Style ──
                    _buildLabel('STYLE'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _styles.map((sty) {
                        final selected = _style == sty;
                        return GestureDetector(
                          onTap: () => setState(() => _style = sty),
                          child: _SelectChip(
                            label: sty,
                            selected: selected,
                          ),
                        );
                      }).toList(),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(_error!,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFFAA4444),
                              fontWeight: FontWeight.w300)),
                    ],

                    const SizedBox(height: 32),

                    // ── Upload Button ──
                    GestureDetector(
                      onTap:
                          _uploading ? null : _uploadToFirebase,
                      child: Container(
                        width: double.infinity,
                        color: _isValid ? _ink : const Color(0xFF3A3834),
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: _uploading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: _sand,
                                  ),
                                )
                              : Text('SAVE TO WARDROBE',
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight:
                                          FontWeight.w500,
                                      letterSpacing: 2.0,
                                      color: _sand)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ADD TO WARDROBE',
                      style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.8,
                          color: _muted)),
                  const SizedBox(height: 6),
                  Text('Upload a piece.',
                      style: GoogleFonts.cormorantGaramond(
                          fontSize: 28,
                          fontWeight: FontWeight.w400,
                          color: _ink)),
                ],
              ),
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _cardBg,
                    border: Border.all(color: _border, width: 0.5),
                  ),
                  child: const Icon(Icons.close, size: 18, color: _ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.8,
            color: _muted));
  }
}

class _ImageSourceBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const cardBg = Color(0xFFFFFFFF);
    const border = Color(0xFFE2E0DC);
    const muted = Color(0xFF8A8784);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: cardBg,
          border: Border.all(color: border, width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: muted),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 9,
                    color: muted,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.6)),
          ],
        ),
      ),
    );
  }
}

class _SelectChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _SelectChip({
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF1A1814);
    const borderStrong = Color(0xFFD8D6D2);
    const cardBg = Color(0xFFFFFFFF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF252320) : cardBg,
        border: Border.all(
          color: selected ? ink : borderStrong,
          width: 0.5,
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.8,
          color: selected ? const Color(0xFFC8C4BE) : const Color(0xFF4A4844),
        ),
      ),
    );
  }
}
