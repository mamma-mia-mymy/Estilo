import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_storage/firebase_storage.dart' as storage;
import 'providers/profile_provider.dart';
import 'skin_tone_screen.dart';

class DemographicScreen extends ConsumerStatefulWidget {
  const DemographicScreen({super.key});

  @override
  ConsumerState<DemographicScreen> createState() => _DemographicScreenState();
}

class _DemographicScreenState extends ConsumerState<DemographicScreen> {
  final TextEditingController nameController = TextEditingController();

  String? selectedGender;
  String? selectedBodyType;
  Uint8List? profileImageBytes;
  bool isUploadingImage = false;
  bool isSaving = false;

  static const Color _bg = Color(0xFF1A1814);
  static const Color _sand = Color(0xFFC8C4BE);
  static const Color _sandDim = Color(0xFF6B6862);
  static const Color _border = Color(0xFF2E2C28);
  static const Color _divider = Color(0xFF2A2825);
  static const Color _timeLabel = Color(0xFF4A4844);
  static const Color _chipSelected = Color(0xFF252320);
  static const Color _inputHint = Color(0xFF3D3B37);

  static const List<String> _genders = [
    'Male', 'Female', 'Non-binary', 'Prefer not to say'
  ];

  static const List<String> _bodyTypes = [
    'Slim', 'Athletic', 'Average', 'Broad', 'Plus'
  ];

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      profileImageBytes = bytes;
      isUploadingImage = true;
    });

    try {
      final uid = auth.FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final ref = storage.FirebaseStorage.instance
            .ref()
            .child('profile_photos')
            .child('$uid.jpg');
        await ref.putData(
          bytes,
          storage.SettableMetadata(contentType: 'image/jpeg'),
        );
      }
    } catch (_) {
      // Upload failed silently — image still shows locally
    } finally {
      if (mounted) setState(() => isUploadingImage = false);
    }
  }

Future<void> _continue() async {
    final uid = auth.FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Validation
    String? errorMessage;
    if (nameController.text.trim().isEmpty) {
      errorMessage = 'Please enter your name';
    } else if (selectedGender == null) {
      errorMessage = 'Please select your gender';
    } else if (selectedBodyType == null) {
      errorMessage = 'Please select your body type';
    }

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w300,
            ),
          ),
          backgroundColor: const Color(0xFF2E2C28),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    // Save demographic data to Firestore
    await ref.read(profileProvider.notifier).updateProfile(
      name: nameController.text.trim(),
      gender: selectedGender,
      bodyType: selectedBodyType,
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) =>  SkinToneScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Watermark
          Positioned(
            bottom: -20,
            right: -10,
            child: Text(
              '02',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 200,
                fontWeight: FontWeight.w300,
                color: _chipSelected,
                height: 1,
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 52),

// Top bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          _StepDot(active: false),
                          SizedBox(width: 5),
                          _StepDot(active: true),
                          SizedBox(width: 5),
                          _StepDot(active: false),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Eyebrow
                  Text(
                    'STEP 1 OF 3',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2.2,
                      color: _sandDim,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Headline
                  Text(
                    'Tell us\nabout you.',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 38,
                      fontWeight: FontWeight.w400,
                      color: _sand,
                      height: 1.05,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Avatar row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            border: Border.all(color: _border, width: 0.5),
                          ),
                          child: isUploadingImage
                              ? const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1,
                                      color: _sand,
                                    ),
                                  ),
                                )
                              : profileImageBytes != null
                                  ? ClipRect(
                                      child: Image.memory(
                                        profileImageBytes!,
                                        fit: BoxFit.cover,
                                        width: 68,
                                        height: 68,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt_outlined,
                                      size: 24,
                                      color: _sandDim,
                                    ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add a profile photo',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w300,
                              color: _sandDim,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'TAP TO UPLOAD',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 1.2,
                              color: _timeLabel,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Name field
                  _FieldLabel(label: 'FULL NAME'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameController,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w300,
                      color: _sand,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Your name',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w300,
                        color: _inputHint,
                      ),
                      border: InputBorder.none,
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: _border, width: 0.5),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: _sand, width: 0.5),
                      ),
                      contentPadding: const EdgeInsets.only(bottom: 10),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Gender chips
                  _FieldLabel(label: 'GENDER'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _genders.map((g) {
                      final selected = selectedGender == g;
                      return GestureDetector(
                        onTap: () => setState(() => selectedGender = g),
                        child: _Chip(label: g, selected: selected),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Body type chips
                  _FieldLabel(label: 'BODY TYPE'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _bodyTypes.map((b) {
                      final selected = selectedBodyType == b;
                      return GestureDetector(
                        onTap: () => setState(() => selectedBodyType = b),
                        child: _Chip(label: b, selected: selected),
                      );
                    }).toList(),
                  ),

                  const Spacer(),

                  // Divider
                  Container(
                    width: double.infinity,
                    height: 0.5,
                    color: _divider,
                  ),

                  const SizedBox(height: 28),

                  // CTA row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'STEP 1\nOF 3',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1.4,
                          color: _timeLabel,
                          height: 1.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: _continue,
                        child: Container(
                          color: _sand,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                          child: Text(
                            'CONTINUE',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 2.2,
                              color: _bg,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.8,
        color: const Color(0xFF6B6862),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  const _Chip({required this.label, required this.selected});

  static const Color _border = Color(0xFF2E2C28);
  static const Color _borderSelected = Color(0xFFC8C4BE);
  static const Color _bgSelected = Color(0xFF252320);
  static const Color _textNormal = Color(0xFF6B6862);
  static const Color _textSelected = Color(0xFFC8C4BE);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? _bgSelected : Colors.transparent,
        border: Border.all(
          color: selected ? _borderSelected : _border,
          width: 0.5,
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w400,
          letterSpacing: 1.2,
          color: selected ? _textSelected : _textNormal,
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool active;
  const _StepDot({required this.active});

  static const Color _active = Color(0xFFC8C4BE);
  static const Color _inactive = Color(0xFF3D3B37);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 32 : 20,
      height: 2,
      decoration: BoxDecoration(
        color: active ? _active : _inactive,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}