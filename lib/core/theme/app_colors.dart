import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ───── Brand Primary ─────
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryBg = Color(0xFFEFF6FF);

  // ───── Accent ─────
  static const Color blue = Color(0xFF2563EB);
  static const Color blueLight = Color(0xFF60A5FA);
  static const Color blueBg = Color(0xFFEFF6FF);
  static const Color blueDark = Color(0xFF1D4ED8);

  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleLight = Color(0xFFA78BFA);
  static const Color purpleBg = Color(0xFFF5F3FF);

  static const Color orange = Color(0xFFF59E0B);
  static const Color orangeLight = Color(0xFFFBBF24);
  static const Color orangeBg = Color(0xFFFFFBEB);

  static const Color red = Color(0xFFEF4444);
  static const Color redLight = Color(0xFFFCA5A5);
  static const Color redBg = Color(0xFFFEF2F2);

  static const Color green = Color(0xFF10B981);
  static const Color greenLight = Color(0xFF34D399);
  static const Color greenBg = Color(0xFFECFDF5);
  static const Color greenDark = Color(0xFF059669);

  static const Color teal = Color(0xFF14B8A6);
  static const Color tealBg = Color(0xFFF0FDFA);

  static const Color pink = Color(0xFFEC4899);
  static const Color pinkBg = Color(0xFFFDF2F8);

  // ───── Surfaces ─────
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF1F5F9);
  static const Color surfaceLighter = Color(0xFFE2E8F0);
  static const Color cardDark = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFF8FAFC);
  static const Color scaffoldBg = Color(0xFFF8FAFC);
  static const Color navBg = Color(0xFFFFFFFF);
  static const Color navBorder = Color(0xFFE2E8F0);

  // ───── Neutrals ─────
  static const Color white = Color(0xFFFFFFFF);
  static const Color whiteSoft = Color(0xFFF8FAFC);
  static const Color whiteMuted = Color(0xFFF1F5F9);
  static const Color greyLight = Color(0xFFE2E8F0);
  static const Color grey = Color(0xFF94A3B8);
  static const Color greyDark = Color(0xFF64748B);
  static const Color greyDarker = Color(0xFF475569);

  // ───── Glassmorphism ─────
  static const Color glassBg = Color(0x0DFFFFFF);
  static const Color glassBgDark = Color(0x0D000000);
  static const Color glassBorder = Color(0x1AFFFFFF);
  static const Color glassBorderDark = Color(0x1A000000);

  // ───── Shimmer ─────
  static const Color shimmerBase = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF1F5F9);

  // ───── Text ─────
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnDark = Color(0xFFF8FAFC);

  // ───── Semantic ─────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF2563EB);

  // ─── Material Design backward-compat ───
  static const Color onSurface = Color(0xFF0F172A);
  static const Color onSurfaceVariant = Color(0xFF475569);
  static const Color primaryContainer = Color(0xFFEFF6FF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF1D4ED8);
  static const Color surfaceContainer = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF8FAFC);
  static const Color surfaceContainerHigh = Color(0xFFF1F5F9);
  static const Color surfaceContainerHighest = Color(0xFFE2E8F0);
  static const Color inverseSurface = Color(0xFF0F172A);
  static const Color inverseOnSurface = Color(0xFFF8FAFC);
  static const Color outline = Color(0xFFE2E8F0);
  static const Color outlineVariant = Color(0xFFCBD5E1);
  static const Color secondary = Color(0xFF475569);
  static const Color secondaryContainer = Color(0xFFF1F5F9);
  static const Color tertiary = Color(0xFF7C3AED);
  static const Color tertiaryContainer = Color(0xFFF5F3FF);
  static const Color errorContainer = Color(0xFFFEF2F2);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF991B1B);
  static const Color surfaceBright = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFF8FAFC);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color primaryFixed = Color(0xFFEFF6FF);
  static const Color primaryFixedDim = Color(0xFFBFDBFE);

  // ─── Stock status ───
  static const Color statusInStock = Color(0xFF059669);
  static const Color statusInStockBg = Color(0xFFECFDF5);
  static const Color statusLowStock = Color(0xFFD97706);
  static const Color statusLowStockBg = Color(0xFFFFFBEB);
  static const Color statusOutOfStock = Color(0xFFDC2626);
  static const Color statusOutOfStockBg = Color(0xFFFEF2F2);
  static const Color statusOverstock = Color(0xFF2563EB);
  static const Color statusOverstockBg = Color(0xFFEFF6FF);

  // ─── Helper ───
  static Color getTextColor(BuildContext context) => textPrimary;
  static Color getMutedColor(BuildContext context) => textMuted;
  static Color getSecondaryTextColor(BuildContext context) => textSecondary;
  static Color getSurfaceColor(BuildContext context) => surface;
  static Color getBorderColor(BuildContext context) => greyLight;
}
