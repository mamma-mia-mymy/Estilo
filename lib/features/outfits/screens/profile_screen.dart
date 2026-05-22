import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

// Import constants from wardrobe_screen.dart or a shared file
// import '../wardrobe/wardrobe_screen.dart' show kStyles, kColors;

const List<String> kStylesProfile = [
  'Casual', 'Formal', 'Vintage', 'Streetwear', 'Minimalist', 'Boho', 'Y2K', 'Old Money'
];
const List<String> kColorsProfile = [
  'Black', 'White', 'Gray', 'Beige', 'Brown',
  'Navy', 'Blue', 'Green', 'Red', 'Pink', 'Yellow', 'Orange', 'Purple',
];
const List<String> kBodyTypes = ['Slim', 'Athletic', 'Average', 'Broad', 'Plus'];
const List<String> kSkinTones = ['Fair', 'Light', 'Medium', 'Olive', 'Tan', 'Deep'];
const List<String> kSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
const List<String> kGenders = ['Male', 'Female', 'Non-binary', 'Prefer not to say'];

// ─── Model ────────────────────────────────────────────────────────────

class UserProfile {
  final String uid;
  final String fullName;
  final String email;
  final String gender;
  final String bodyType;
  final String skinTone;
  final String clothingSize;
  final List<String> favoriteColors;
  final List<String> preferredStyles;
  final String profileImage;

  const UserProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.gender,
    required this.bodyType,
    required this.skinTone,
    required this.clothingSize,
    required this.favoriteColors,
    required this.preferredStyles,
    required this.profileImage,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc, String email) {
    final d = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
fullName: d['name'] ?? d['fullName'] ?? '',
      email: email,
      gender: d['gender'] ?? '',
      bodyType: d['bodyType'] ?? '',
      skinTone: d['skinTone'] ?? '',
      clothingSize: d['clothingSize'] ?? '',
      favoriteColors: List<String>.from(d['favoriteColors'] ?? []),
      preferredStyles: List<String>.from(d['preferredStyles'] ?? []),
      profileImage: d['profileImage'] ?? '',
    );
  }

  UserProfile copyWith({
    String? fullName,
    String? gender,
    String? bodyType,
    String? skinTone,
    String? clothingSize,
    List<String>? favoriteColors,
    List<String>? preferredStyles,
    String? profileImage,
  }) =>
      UserProfile(
        uid: uid,
        fullName: fullName ?? this.fullName,
        email: email,
        gender: gender ?? this.gender,
        bodyType: bodyType ?? this.bodyType,
        skinTone: skinTone ?? this.skinTone,
        clothingSize: clothingSize ?? this.clothingSize,
        favoriteColors: favoriteColors ?? this.favoriteColors,
        preferredStyles: preferredStyles ?? this.preferredStyles,
        profileImage: profileImage ?? this.profileImage,
      );
}

// ─── Repository ───────────────────────────────────────────────────────

class ProfileRepository {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;

  User get _user => _auth.currentUser!;

  Stream<UserProfile> watchProfile() => _db
      .collection('users')
      .doc(_user.uid)
      .snapshots()
      .map((doc) => UserProfile.fromFirestore(doc, _user.email ?? ''));

  Future<void> updateProfile(Map<String, dynamic> data) =>
      _db.collection('users').doc(_user.uid).set(data, SetOptions(merge: true));

  Future<String> uploadProfilePhoto(File file) async {
    final ref = _storage
        .ref()
        .child('profile_photos')
        .child('${_user.uid}.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<void> signOut() => _auth.signOut();
}

// ─── Providers ────────────────────────────────────────────────────────

final profileRepositoryProvider = Provider((_) => ProfileRepository());

final profileStreamProvider = StreamProvider<UserProfile>((ref) =>
    ref.watch(profileRepositoryProvider).watchProfile());

// ─── Constants ────────────────────────────────────────────────────────

const _bg = Color(0xFFF5F4F2);
const _ink = Color(0xFF1A1814);
const _sand = Color(0xFFC8C4BE);
const _muted = Color(0xFF8A8784);
const _cardBg = Color(0xFFFFFFFF);
const _border = Color(0xFFE2E0DC);
const _borderStrong = Color(0xFFD8D6D2);
const _darkInk = Color(0xFF252320);
const _darkMuted = Color(0xFF6B6862);

// ─── Screen ───────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileStreamProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: profileAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: _ink, strokeWidth: 1)),
        error: (e, _) => Center(
            child: Text('Could not load profile',
                style: GoogleFonts.inter(color: _muted))),
        data: (profile) => _ProfileBody(profile: profile),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  final UserProfile profile;
  const _ProfileBody({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(context, ref, profile),
            _buildStatsRow(context),
            _buildSectionHeader('PERSONALIZATION'),
            _buildPrefTile(
              context,
              icon: Icons.face_outlined,
              label: 'Skin Tone',
              value: profile.skinTone.isNotEmpty
                  ? profile.skinTone
                  : 'Not set',
              onTap: () => _openEdit(context, profile, _EditMode.skinTone),
            ),
            _buildPrefTile(
              context,
              icon: Icons.accessibility_new_outlined,
              label: 'Body Type',
              value: profile.bodyType.isNotEmpty
                  ? profile.bodyType
                  : 'Not set',
              onTap: () => _openEdit(context, profile, _EditMode.bodyType),
            ),
            _buildPrefTile(
              context,
              icon: Icons.palette_outlined,
              label: 'Aesthetic',
              value: profile.preferredStyles.isNotEmpty
                  ? profile.preferredStyles.join(', ')
                  : 'Not set',
              onTap: () =>
                  _openEdit(context, profile, _EditMode.styles),
            ),
            _buildPrefTile(
              context,
              icon: Icons.color_lens_outlined,
              label: 'Colour Palette',
              value: profile.favoriteColors.isNotEmpty
                  ? profile.favoriteColors.join(', ')
                  : 'Not set',
              onTap: () =>
                  _openEdit(context, profile, _EditMode.colors),
            ),
            _buildPrefTile(
              context,
              icon: Icons.straighten_outlined,
              label: 'Clothing Size',
              value: profile.clothingSize.isNotEmpty
                  ? profile.clothingSize
                  : 'Not set',
              last: true,
              onTap: () => _openEdit(context, profile, _EditMode.size),
            ),
            _buildSectionHeader('ACCOUNT'),
            _buildPrefTile(
              context,
              icon: Icons.person_outline,
              label: 'Full Name',
              value: profile.fullName.isNotEmpty
                  ? profile.fullName
                  : 'Not set',
              onTap: () => _openEdit(context, profile, _EditMode.name),
            ),
            _buildPrefTile(
              context,
              icon: Icons.wc_outlined,
              label: 'Gender',
              value: profile.gender.isNotEmpty ? profile.gender : 'Not set',
              onTap: () => _openEdit(context, profile, _EditMode.gender),
            ),
            _buildPrefTile(
              context,
              icon: Icons.mail_outline,
              label: 'Email',
              value: profile.email,
              last: true,
              onTap: null,
            ),
            _buildSectionHeader('SETTINGS'),
            _buildPrefTile(
              context,
              icon: Icons.notifications_none_outlined,
              label: 'Notifications',
              value: '',
              onTap: () {},
            ),
            _buildPrefTile(
              context,
              icon: Icons.location_on_outlined,
              label: 'Location Access',
              value: '',
              onTap: () {},
            ),
            _buildPrefTile(
              context,
              icon: Icons.lock_outline,
              label: 'Privacy & Security',
              value: '',
              last: true,
              onTap: () {},
            ),
            const SizedBox(height: 16),
            _buildSignOut(context, ref),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(
      BuildContext context, WidgetRef ref, UserProfile profile) {
    return Container(
      color: _ink,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _pickAndUploadPhoto(context, ref),
            child: Stack(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  color: _darkInk,
                  child: profile.profileImage.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: profile.profileImage,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _initials(profile),
                        )
                      : _initials(profile),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    color: _sand,
                    child: const Icon(Icons.camera_alt_outlined,
                        size: 12, color: _ink),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    profile.fullName.isNotEmpty
                        ? profile.fullName
                        : 'Your Name',
                    style: GoogleFonts.cormorantGaramond(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: _sand)),
                const SizedBox(height: 4),
                Text(profile.email,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w300,
                        color: _darkMuted)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: const Color(0xFF2E2C28), width: 0.5)),
                  child: Text('MEMBER SINCE 2024',
                      style: GoogleFonts.inter(
                          fontSize: 9,
                          letterSpacing: 1.2,
                          color: _darkMuted)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _initials(UserProfile profile) {
    final initial = profile.fullName.isNotEmpty
        ? profile.fullName[0].toUpperCase()
        : 'T';
    return Center(
      child: Text(initial,
          style: GoogleFonts.cormorantGaramond(
              fontSize: 30,
              fontWeight: FontWeight.w300,
              color: _sand)),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        children: [
          Expanded(
              child:
                  _StatPill(value: '0', label: 'Pieces')),
          const SizedBox(width: 10),
          Expanded(
              child:
                  _StatPill(value: '0', label: 'Outfits')),
          const SizedBox(width: 10),
          Expanded(
              child:
                  _StatPill(value: '—', label: 'Avg Score')),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
      child: Text(title,
          style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 2.0,
              color: _muted)),
    );
  }

  Widget _buildPrefTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback? onTap,
    bool last = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _cardBg,
          border: Border(
            left: const BorderSide(color: _border, width: 0.5),
            right: const BorderSide(color: _border, width: 0.5),
            top: const BorderSide(color: _border, width: 0.5),
            bottom: BorderSide(
                color: last ? _border : Colors.transparent, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              color: _bg,
              child: Center(
                  child: Icon(icon, size: 16, color: const Color(0xFF4A4844))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label.toUpperCase(),
                      style: GoogleFonts.inter(
                          fontSize: 9,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w500,
                          color: _muted)),
                  if (value.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(value,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                            color: _ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right,
                  size: 16, color: _muted),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOut(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () async {
          await ref.read(profileRepositoryProvider).signOut();
          // Navigate to login — replace with your actual route
          if (context.mounted) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/login', (_) => false);
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration:
              BoxDecoration(border: Border.all(color: _border, width: 0.5)),
          child: Center(
            child: Text('SIGN OUT',
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2.0,
                    color: _muted)),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(
      BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    final file = File(picked.path);
    try {
      final url = await ref
          .read(profileRepositoryProvider)
          .uploadProfilePhoto(file);
      await ref
          .read(profileRepositoryProvider)
          .updateProfile({'profileImage': url});
    } catch (_) {}
  }

  void _openEdit(
      BuildContext context, UserProfile profile, _EditMode mode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(profile: profile, mode: mode),
    );
  }
}

// ─── Edit modes ───────────────────────────────────────────────────────

enum _EditMode {
  name,
  gender,
  skinTone,
  bodyType,
  styles,
  colors,
  size,
}

// ─── Edit Sheet ───────────────────────────────────────────────────────

class _EditProfileSheet extends ConsumerStatefulWidget {
  final UserProfile profile;
  final _EditMode mode;
  const _EditProfileSheet({required this.profile, required this.mode});

  @override
  ConsumerState<_EditProfileSheet> createState() =>
      _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late TextEditingController _nameCtrl;
  late String? _singleValue;
  late List<String> _multiValues;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl = TextEditingController(text: p.fullName);
    _singleValue = switch (widget.mode) {
      _EditMode.gender => p.gender.isNotEmpty ? p.gender : null,
      _EditMode.skinTone => p.skinTone.isNotEmpty ? p.skinTone : null,
      _EditMode.bodyType => p.bodyType.isNotEmpty ? p.bodyType : null,
      _EditMode.size => p.clothingSize.isNotEmpty ? p.clothingSize : null,
      _ => null,
    };
    _multiValues = switch (widget.mode) {
      _EditMode.styles => List.from(p.preferredStyles),
      _EditMode.colors => List.from(p.favoriteColors),
      _ => [],
    };
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String get _title => switch (widget.mode) {
        _EditMode.name => 'Full Name',
        _EditMode.gender => 'Gender',
        _EditMode.skinTone => 'Skin Tone',
        _EditMode.bodyType => 'Body Type',
        _EditMode.styles => 'Aesthetic',
        _EditMode.colors => 'Colour Palette',
        _EditMode.size => 'Clothing Size',
      };

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
            Text('EDIT',
                style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.8,
                    color: _muted)),
            const SizedBox(height: 6),
            Text(_title,
                style: GoogleFonts.cormorantGaramond(
                    fontSize: 26,
                    fontWeight: FontWeight.w400,
                    color: _ink)),
            const SizedBox(height: 24),
            _buildEditor(),
            const SizedBox(height: 24),
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
                      : Text('SAVE',
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

  Widget _buildEditor() {
    switch (widget.mode) {
      case _EditMode.name:
        return TextField(
          controller: _nameCtrl,
          style: GoogleFonts.inter(fontSize: 15, color: _ink),
          decoration: InputDecoration(
            hintText: 'Your full name',
            hintStyle: GoogleFonts.inter(fontSize: 15, color: _muted),
            enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: _border, width: 0.5)),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: _ink, width: 0.5)),
            contentPadding: const EdgeInsets.only(bottom: 8),
          ),
        );

      case _EditMode.gender:
        return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kGenders
                .map((g) => _Chip(
                    label: g,
                    selected: _singleValue == g,
                    onTap: () => setState(() => _singleValue = g)))
                .toList());

      case _EditMode.skinTone:
        return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kSkinTones
                .map((s) => _Chip(
                    label: s,
                    selected: _singleValue == s,
                    onTap: () => setState(() => _singleValue = s)))
                .toList());

      case _EditMode.bodyType:
        return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kBodyTypes
                .map((b) => _Chip(
                    label: b,
                    selected: _singleValue == b,
                    onTap: () => setState(() => _singleValue = b)))
                .toList());

      case _EditMode.size:
        return Row(
          children: kSizes.map((s) {
            final sel = _singleValue == s;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _singleValue = s),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFF252320) : _cardBg,
                    border: Border.all(
                        color: sel ? _ink : _borderStrong, width: 0.5),
                  ),
                  child: Center(
                    child: Text(s,
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            color: sel ? _sand : _muted)),
                  ),
                ),
              ),
            );
          }).toList(),
        );

      case _EditMode.styles:
        return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kStylesProfile
                .map((s) => _Chip(
                    label: s,
                    selected: _multiValues.contains(s),
                    onTap: () => setState(() => _multiValues.contains(s)
                        ? _multiValues.remove(s)
                        : _multiValues.add(s))))
                .toList());

      case _EditMode.colors:
        return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kColorsProfile
                .map((c) => _Chip(
                    label: c,
                    selected: _multiValues.contains(c),
                    onTap: () => setState(() => _multiValues.contains(c)
                        ? _multiValues.remove(c)
                        : _multiValues.add(c))))
                .toList());
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final data = switch (widget.mode) {
      _EditMode.name => {'fullName': _nameCtrl.text.trim()},
      _EditMode.gender => {'gender': _singleValue ?? ''},
      _EditMode.skinTone => {'skinTone': _singleValue ?? ''},
      _EditMode.bodyType => {'bodyType': _singleValue ?? ''},
      _EditMode.size => {'clothingSize': _singleValue ?? ''},
      _EditMode.styles => {'preferredStyles': _multiValues},
      _EditMode.colors => {'favoriteColors': _multiValues},
    };
    await ref.read(profileRepositoryProvider).updateProfile(data);
    if (mounted) Navigator.pop(context);
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  const _StatPill({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
          color: _cardBg, border: Border.all(color: _border, width: 0.5)),
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.cormorantGaramond(
                  fontSize: 26, fontWeight: FontWeight.w400, color: _ink)),
          const SizedBox(height: 2),
          Text(label.toUpperCase(),
              style: GoogleFonts.inter(
                  fontSize: 9, letterSpacing: 1.2, color: _muted)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip(
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