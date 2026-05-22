import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final String? message;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    this.message,
    required this.child,
  });

  static const Color _ink = Color(0xFF1A1814);
  static const Color _sand = Color(0xFFC8C4BE);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: _ink.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: _sand,
                      ),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        message!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: _sand,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class LoadingButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final double height;

  const LoadingButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.label,
    this.backgroundColor = const Color(0xFF1A1814),
    this.foregroundColor = const Color(0xFFC8C4BE),
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          disabledBackgroundColor: backgroundColor.withOpacity(0.5),
        ),
        child: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: foregroundColor,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 3.5,
                  color: foregroundColor,
                ),
              ),
      ),
    );
  }
}
