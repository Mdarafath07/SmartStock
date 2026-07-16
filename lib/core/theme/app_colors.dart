import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ───── Black Primary ─────
  static const Color primary = Color(0xFF111111);
  static const Color primaryDark = Color(0xFF000000);
  static const Color primaryLight = Color(0xFF374151);

  // ───── Surfaces ─────
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFE2E8F0);
  static const Color surfaceLighter = Color(0xFFCBD5E1);
  static const Color cardDark = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFF8FAFC);
  static const Color scaffoldBg = Color(0xFFF8FAFC);
  static const Color navBg = Color(0xFFFFFFFF);
  static const Color navBorder = Color(0xFFE2E8F0);

  // ───── Neutrals ─────
  static const Color white = Color(0xFFFFFFFF);
  static const Color whiteSoft = Color(0xFFF8FAFC);
  static const Color whiteMuted = Color(0xFFE2E8F0);
  static const Color greyLight = Color(0xFFCBD5E1);
  static const Color grey = Color(0xFF9CA3AF);
  static const Color greyDark = Color(0xFF6B7280);
  static const Color greyDarker = Color(0xFF374151);

  // ───── Glassmorphism ─────
  static const Color glassBg = Color(0x0DFFFFFF);
  static const Color glassBgDark = Color(0x0D000000);
  static const Color glassBorder = Color(0x1AFFFFFF);
  static const Color glassBorderDark = Color(0x1A000000);

  // ───── Shimmer ─────
  static const Color shimmerBase = Color(0xFFCBD5E1);
  static const Color shimmerHighlight = Color(0xFFE2E8F0);

  // ───── Text ─────
  static const Color textPrimary = Color(0xFF111111);
  static const Color textNormal = Color(0xFF374151);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textOnDark = Color(0xFFF8FAFC);

  // ───── Icons ─────
  static const Color iconPrimaryAction = Color(0xFF111111);
  static const Color iconCardAction = Color(0xFF374151);
  static const Color iconNavigationActive = Color(0xFF111111);
  static const Color iconNavigationInactive = Color(0xFF9CA3AF);

  // ───── Semantic / Status ─────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // ─── Material Design backward-compat ───
  static const Color onSurface = Color(0xFF050B14);
  static const Color onSurfaceVariant = Color(0xFF1E293B);
  static const Color primaryContainer = Color(0xFFF3F4F6);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF111111);
  static const Color surfaceContainer = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF8FAFC);
  static const Color surfaceContainerHigh = Color(0xFFE2E8F0);
  static const Color surfaceContainerHighest = Color(0xFFCBD5E1);
  static const Color inverseSurface = Color(0xFF050B14);
  static const Color inverseOnSurface = Color(0xFFF8FAFC);
  static const Color outline = Color(0xFFCBD5E1);
  static const Color outlineVariant = Color(0xFFCBD5E1);
  static const Color secondary = Color(0xFF374151);
  static const Color secondaryContainer = Color(0xFFE2E8F0);
  static const Color tertiary = Color(0xFF374151);
  static const Color tertiaryContainer = Color(0xFFE2E8F0);
  static const Color errorContainer = Color(0xFFFEF2F2);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF991B1B);
  static const Color surfaceBright = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFF8FAFC);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color primaryFixed = Color(0xFFF3F4F6);
  static const Color primaryFixedDim = Color(0xFFD1D5DB);

  // ─── Stock status ───
  static const Color statusInStock = Color(0xFF059669);
  static const Color statusInStockBg = Color(0xFFECFDF5);
  static const Color statusLowStock = Color(0xFFD97706);
  static const Color statusLowStockBg = Color(0xFFFFFBEB);
  static const Color statusOutOfStock = Color(0xFFDC2626);
  static const Color statusOutOfStockBg = Color(0xFFFEF2F2);
  static const Color statusOverstock = Color(0xFF111111);
  static const Color statusOverstockBg = Color(0xFFF3F4F6);

  // ─── Helper ───
  static Color getTextColor(BuildContext context) => textPrimary;
  static Color getMutedColor(BuildContext context) => textMuted;
  static Color getSecondaryTextColor(BuildContext context) => textSecondary;
  static Color getSurfaceColor(BuildContext context) => surface;
  static Color getBorderColor(BuildContext context) => greyLight;
}
