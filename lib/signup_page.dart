import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'utils/validators.dart';
import 'providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  static const Color _bg = Color(0xFFC8C4BE);
  static const Color _ink = Color(0xFF1A1814);
  static const Color _muted = Color(0xFF4A4843);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    // Clear any previous error
    ref.read(authProvider.notifier).clearError();
    
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    await ref.read(authProvider.notifier).signUp(email: email, password: password);
    
    // Get the updated auth state
    final authState = ref.read(authProvider);
    
    // Only navigate to login if there was NO error (signup was successful)
    if (authState.errorMessage == null && mounted) {
      // Success - navigate to login
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Account created! Please sign in to continue.',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          backgroundColor: _ink,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/login');
    }
  }

@override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Navigation handled by router redirect - no manual navigation needed

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Positioned(
            top: 24,
            left: 8,
            child: Text(
              'T',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 180,
                fontWeight: FontWeight.w300,
                color: _ink.withOpacity(0.06),
                height: 1,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 48),
                    Text(
                      'TERNOVA',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 5,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 52,
                      height: 1,
                      color: _ink,
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'Create\nAccount',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 44,
                        fontWeight: FontWeight.w400,
                        color: _ink,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Start your style journey with Ternova.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        color: _muted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildFieldLabel('EMAIL ADDRESS'),
                    const SizedBox(height: 10),
                    _buildTextField(
                      controller: _emailController,
                      hint: 'you@ternova.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: validateEmail,
                    ),
                    const SizedBox(height: 28),
                    _buildFieldLabel('PASSWORD'),
                    const SizedBox(height: 10),
                    _buildTextField(
                      controller: _passwordController,
                      hint: '••••••••',
                      obscure: _obscurePassword,
                      suffix: GestureDetector(
                        onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 18,
                            color: _muted,
                          ),
                        ),
                      ),
                      validator: validatePassword,
                    ),
                    const SizedBox(height: 28),
                    _buildFieldLabel('CONFIRM PASSWORD'),
                    const SizedBox(height: 10),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      hint: '••••••••',
                      obscure: _obscureConfirmPassword,
                      suffix: GestureDetector(
                        onTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 18,
                            color: _muted,
                          ),
                        ),
                      ),
                      validator: (value) => validateConfirmPassword(_passwordController.text, value),
                    ),
                    if (authState.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        authState.errorMessage!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 36),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: TextButton(
                        onPressed: authState.isLoading ? null : _handleSignup,
                        style: TextButton.styleFrom(
                          backgroundColor: _ink,
                          foregroundColor: _bg,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: authState.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: _bg,
                                ),
                              )
                            : Text(
                                'CREATE ACCOUNT',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 3.5,
                                  color: _bg,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        children: [
                          Text(
                            'ALREADY MEMBER?',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 1.5,
                              color: _muted,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/login'),
                            child: Text(
                              'SIGN IN',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.5,
                                color: _ink,
                                decoration: TextDecoration.underline,
                                decorationColor: _ink,
                                decorationThickness: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_outline, size: 18, color: _ink.withOpacity(0.35)),
                          const SizedBox(width: 28),
                          Icon(Icons.verified_user_outlined, size: 18, color: _ink.withOpacity(0.35)),
                          const SizedBox(width: 28),
                          Icon(Icons.fingerprint, size: 18, color: _ink.withOpacity(0.35)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        'TERNOVA INTERNATIONAL © 2024\nALL RIGHTS RESERVED',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1.8,
                          color: _ink.withOpacity(0.38),
                          height: 1.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.6,
        color: _muted,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w300,
        color: _ink,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w300,
          color: _ink.withOpacity(0.3),
        ),
        suffix: suffix,
        border: InputBorder.none,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: _ink.withOpacity(0.4),
            width: 0.5,
          ),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Color(0xFF1A1814),
            width: 0.5,
          ),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Colors.red,
            width: 0.5,
          ),
        ),
        contentPadding: const EdgeInsets.only(bottom: 10),
      ),
    );
  }
}
