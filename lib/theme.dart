/// theme.dart — The shared look, centralized so every screen shares
/// one palette.
///
/// Deep plum primary, antique gold accent, warm cream surfaces in
/// light mode; a rich plum-charcoal counterpart in dark mode with the
/// gold still doing the accent work. Follows the system brightness —
/// main.dart wires [buildLightTheme] / [buildDarkTheme] into
/// MaterialApp.
///
/// Also home to the per-category colors: [categoryColor] assigns each
/// category a stable color from a curated palette (hash of the
/// category name), so a category looks the same on the home list, the
/// browse page, and the detail page. Pure presentation — nothing here
/// touches data or behavior.
library;

import 'package:flutter/material.dart';

/// The palette. Hex values are the design's source of truth.
class AppColors {
  AppColors._();

  /// Primary plum.
  static const Color plum = Color(0xFF4A148C);

  /// Deepest plum — AppBar gradient foot, snackbar background.
  static const Color plumDeep = Color(0xFF2E0A47);

  /// Brightest plum — AppBar gradient head.
  static const Color plumBright = Color(0xFF6A1FA2);

  /// Lighter plum that stays legible as a primary on dark surfaces.
  static const Color plumLight = Color(0xFF9D72D6);

  /// Antique gold — the one accent everywhere.
  static const Color gold = Color(0xFFC9A227);

  /// Paler gold for dark mode and for text/marks on plum.
  static const Color goldLight = Color(0xFFE3C566);

  /// Warm cream — light-mode surface.
  static const Color cream = Color(0xFFFFFBF2);

  /// Near-white warm card surface (light mode).
  static const Color creamCard = Color(0xFFFFFDF7);

  /// Warm ink for light-mode text.
  static const Color ink = Color(0xFF2B2135);

  /// Plum-charcoal scaffold background (dark mode).
  static const Color coal = Color(0xFF17101F);

  /// Plum-charcoal card surface (dark mode).
  static const Color coalCard = Color(0xFF231831);

  /// Muted red, reserved for destructive actions (delete).
  static const Color destructive = Color(0xFFB3261E);
}

/// Curated category palette — twelve harmonious colors.
/// Assignment is by hash (see [categoryColor]), so which category gets
/// which color is arbitrary but permanently stable.
const List<Color> _categoryPalette = [
  Color(0xFF6A1B9A), // purple
  Color(0xFFAD1457), // magenta
  Color(0xFFC62828), // crimson
  Color(0xFFD84315), // rust
  Color(0xFFEF6C00), // amber-orange
  Color(0xFF827717), // antique olive-gold
  Color(0xFF2E7D32), // green
  Color(0xFF00838F), // teal
  Color(0xFF1565C0), // blue
  Color(0xFF3949AB), // indigo
  Color(0xFF6D4C41), // brown
  Color(0xFF546E7A), // slate
];

/// The stable color for a category name (djb2 hash over the name, mod
/// the palette size). Null/empty names fall back to plum.
Color categoryColor(String? category) {
  if (category == null || category.isEmpty) return AppColors.plum;
  var hash = 5381;
  for (final unit in category.codeUnits) {
    hash = ((hash << 5) + hash + unit) & 0x7FFFFFFF;
  }
  return _categoryPalette[hash % _categoryPalette.length];
}

/// Gradient plum background shared by every AppBar (used as
/// `flexibleSpace`). Vertical: bright plum at the top melting into the
/// deepest plum at the foot.
class PlumAppBarBackground extends StatelessWidget {
  const PlumAppBarBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.plumBright,
            AppColors.plum,
            AppColors.plumDeep,
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
    );
  }
}

/// Small solid pill in the category's color, white label. Used wherever
/// an item's category is shown as a chip. When [onTap] is given, the
/// chip becomes a tappable link (ripple + a small chevron) — used to
/// jump to that category's item list.
class CategoryChip extends StatelessWidget {
  final String category;
  final VoidCallback? onTap;
  const CategoryChip({super.key, required this.category, this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          category,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: 2),
          const Icon(
            Icons.chevron_right,
            size: 13,
            color: Colors.white70,
          ),
        ],
      ],
    );
    if (onTap == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: categoryColor(category),
          borderRadius: BorderRadius.circular(999),
        ),
        child: label,
      );
    }
    return Material(
      color: categoryColor(category),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: label,
        ),
      ),
    );
  }
}

/// A small filled circle in the category's color — the lightweight
/// alternative to [CategoryChip] for dense lists and picker rows.
class CategoryDot extends StatelessWidget {
  final String? category;
  final double size;
  const CategoryDot({super.key, required this.category, this.size = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: categoryColor(category),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Gold-tinted badge marking one of the user's own items.
class MyItemBadge extends StatelessWidget {
  const MyItemBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: dark ? 0.28 : 0.20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.55),
        ),
      ),
      child: Text(
        'My item',
        style: TextStyle(
          color: dark ? AppColors.goldLight : const Color(0xFF7A5C00),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

ThemeData buildLightTheme() => _buildTheme(Brightness.light);
ThemeData buildDarkTheme() => _buildTheme(Brightness.dark);

ThemeData _buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final seed = ColorScheme.fromSeed(
    seedColor: AppColors.plum,
    brightness: brightness,
  );
  final scheme = seed.copyWith(
    primary: dark ? AppColors.plumLight : AppColors.plum,
    onPrimary: dark ? AppColors.plumDeep : AppColors.cream,
    secondary: dark ? AppColors.goldLight : AppColors.gold,
    onSecondary: AppColors.plumDeep,
    surface: dark ? AppColors.coal : AppColors.cream,
    onSurface: dark ? const Color(0xFFF2EAD8) : AppColors.ink,
    surfaceContainerLowest:
        dark ? const Color(0xFF100A16) : AppColors.creamCard,
    surfaceContainerLow:
        dark ? const Color(0xFF1D1328) : const Color(0xFFFAF3E3),
    surfaceContainer:
        dark ? AppColors.coalCard : const Color(0xFFF6EDDC),
    surfaceContainerHigh:
        dark ? const Color(0xFF2A1D3D) : const Color(0xFFF0E4CB),
    surfaceContainerHighest:
        dark ? const Color(0xFF33254A) : const Color(0xFFEADFC4),
  );

  final cardColor = dark ? AppColors.coalCard : AppColors.creamCard;
  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: scheme.outlineVariant),
  );

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: const AppBarThemeData(
      backgroundColor: AppColors.plumDeep,
      foregroundColor: Color(0xFFFFF3D6),
      iconTheme: IconThemeData(color: Color(0xFFFFF3D6)),
      actionsIconTheme: IconThemeData(color: AppColors.goldLight),
      titleTextStyle: TextStyle(
        color: Color(0xFFFFF3D6),
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.1,
      ),
      elevation: 2,
    ),
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: dark ? 1 : 1.5,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surfaceContainerHigh,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: dark ? AppColors.goldLight : AppColors.gold,
      foregroundColor: AppColors.plumDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: cardColor,
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gold, width: 2),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.plumDeep,
      contentTextStyle: const TextStyle(color: Color(0xFFFFF3D6)),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.onSurface.withValues(alpha: 0.08),
      thickness: 1,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: dark ? AppColors.plumLight : AppColors.plum,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.gold
            : null,
      ),
      checkColor: const WidgetStatePropertyAll(AppColors.plumDeep),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: dark ? AppColors.goldLight : AppColors.gold,
    ),
  );
}
