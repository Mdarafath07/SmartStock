import 'package:flutter/material.dart';

class AppTextStyles {
  AppTextStyles._();

  static const String headlineFont = 'Hanken Grotesk';
  static const String bodyFont = 'Inter';
  static const String labelFont = 'Geist';

  static const TextStyle displayLg = TextStyle(
    fontFamily: headlineFont,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 56 / 48,
    letterSpacing: -0.02,
  );

  static const TextStyle headlineLg = TextStyle(
    fontFamily: headlineFont,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 40 / 32,
    letterSpacing: -0.01,
  );

  static const TextStyle headlineLgMobile = TextStyle(
    fontFamily: headlineFont,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
  );

  static const TextStyle titleMd = TextStyle(
    fontFamily: headlineFont,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
  );

  static const TextStyle bodyLg = TextStyle(
    fontFamily: bodyFont,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: bodyFont,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
  );

  static const TextStyle labelMd = TextStyle(
    fontFamily: labelFont,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    letterSpacing: 0.05,
  );

  static const TextStyle labelSm = TextStyle(
    fontFamily: labelFont,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 14 / 11,
  );

  static const TextStyle codeSm = TextStyle(
    fontFamily: labelFont,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 18 / 13,
  );
}
