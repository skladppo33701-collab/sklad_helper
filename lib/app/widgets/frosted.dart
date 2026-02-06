import 'dart:ui';
import 'package:flutter/material.dart';

class Frosted extends StatelessWidget {
  const Frosted({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding = const EdgeInsets.all(16),
    this.tint,
    this.borderAlpha = 0.06,
    this.blurSigma = 18,
  });

  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final Color? tint;
  final double borderAlpha;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final baseTint = tint ?? const Color(0xFF141A1C);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: baseTint.withValues(alpha: 0.70),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: borderAlpha),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
