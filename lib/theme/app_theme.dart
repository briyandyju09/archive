import 'package:flutter/material.dart';

import '../models/camera_skin.dart';
import 'app_dimens.dart';
import 'app_skin_extension.dart';

export 'app_dimens.dart';

/// Builds a [ThemeData] from whichever [CameraSkin] is current — FIELD UNIT
/// 04's identity is no longer a single fixed constant set; it's the default
/// (Night Vision) skin, and every screen/widget reads its colors and text
/// styles through `context.skin` (see app_skin_extension.dart) rather than
/// a static constant, so a different equipped/shooting camera reskins the
/// whole app.
class AppTheme {
  AppTheme._();

  static ThemeData themeFor(CameraSkin skin) {
    final scheme = ColorScheme.dark(
      primary: skin.amber,
      onPrimary: skin.black,
      primaryContainer: skin.graphite,
      onPrimaryContainer: skin.amber,
      secondary: skin.dimAmber,
      onSecondary: skin.lcdWhite,
      secondaryContainer: skin.graphite,
      onSecondaryContainer: skin.dimAmber,
      tertiary: skin.lcdGreen,
      onTertiary: skin.black,
      tertiaryContainer: skin.graphite,
      onTertiaryContainer: skin.lcdGreen,
      error: skin.warningRed,
      onError: skin.black,
      errorContainer: skin.graphite,
      onErrorContainer: skin.warningRed,
      surface: skin.black,
      onSurface: skin.lcdWhite,
      onSurfaceVariant: skin.dimAmber,
      surfaceContainerHigh: skin.charcoal,
      surfaceContainerHighest: skin.graphite,
      outline: skin.graphite,
      outlineVariant: skin.graphite,
      shadow: skin.black,
      scrim: skin.black,
      inversePrimary: skin.amber,
      inverseSurface: skin.lcdWhite,
      onInverseSurface: skin.black,
      surfaceTint: Colors.transparent,
    );
    final base = ThemeData(colorScheme: scheme, useMaterial3: true, brightness: Brightness.dark);
    return _apply(base, scheme, skin);
  }

  static ThemeData _apply(ThemeData base, ColorScheme scheme, CameraSkin skin) {
    final textTheme = _textTheme(base.textTheme, skin);
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      dividerColor: skin.graphite,
      splashFactory: NoSplash.splashFactory,
      highlightColor: skin.amber.withValues(alpha: 0.08),
      extensions: [AppSkinExtension(skin)],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: skin.uppercaseLabel(fontSize: 15, color: skin.lcdWhite),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.panel),
          side: BorderSide(color: skin.graphite, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: skin.charcoal,
          foregroundColor: skin.amber,
          side: BorderSide(color: skin.amber, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.control)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: skin.uppercaseLabel(fontSize: 13, color: skin.amber),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: skin.lcdWhite,
          textStyle: skin.uppercaseLabel(fontSize: 12.5, color: skin.lcdWhite),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: skin.charcoal,
        selectedColor: skin.charcoal,
        side: BorderSide(color: skin.graphite),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.control)),
        labelStyle: skin.uppercaseLabel(fontSize: 11.5, color: skin.lcdWhite),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: skin.charcoal,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return skin.uppercaseLabel(fontSize: 10.5, color: selected ? skin.amber : skin.mutedText);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? skin.amber : skin.mutedText, size: 24);
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: skin.charcoal,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.panel),
          side: BorderSide(color: skin.graphite, width: 1),
        ),
        titleTextStyle: skin.uppercaseLabel(fontSize: 14, color: skin.lcdWhite),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: skin.charcoal,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          side: BorderSide(color: skin.graphite, width: 1),
        ),
        textStyle: skin.uppercaseLabel(fontSize: 12, color: skin.lcdWhite),
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: skin.amber,
        inactiveTrackColor: skin.graphite,
        thumbColor: skin.amber,
        overlayColor: skin.amber.withValues(alpha: 0.15),
        trackHeight: 2,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: skin.amber,
        linearTrackColor: skin.graphite,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: skin.charcoal,
        contentTextStyle: skin.readout(fontSize: 13, color: skin.lcdWhite),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          side: BorderSide(color: skin.graphite),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, CameraSkin skin) {
    return base.copyWith(
      displayLarge: skin.display(fontSize: 57, color: skin.warmWhite),
      displayMedium: skin.display(fontSize: 45, color: skin.warmWhite),
      displaySmall: skin.display(fontSize: 36, color: skin.warmWhite),
      headlineLarge: skin.display(fontSize: 40, color: skin.warmWhite),
      headlineMedium: skin.display(fontSize: 34, color: skin.warmWhite),
      headlineSmall: skin.display(fontSize: 28, color: skin.warmWhite),
      titleLarge: skin.uppercaseLabel(fontSize: 16, color: skin.lcdWhite),
      titleMedium: skin.uppercaseLabel(fontSize: 14, color: skin.lcdWhite),
      titleSmall: skin.uppercaseLabel(fontSize: 12.5, color: skin.lcdWhite),
      bodyLarge: skin.prose(fontSize: 15, color: skin.lcdWhite),
      bodyMedium: skin.prose(fontSize: 14, color: skin.lcdWhite),
      bodySmall: skin.prose(fontSize: 12.5, color: skin.mutedText),
      labelLarge: skin.uppercaseLabel(fontSize: 13, color: skin.lcdWhite),
      labelMedium: skin.uppercaseLabel(fontSize: 11.5, color: skin.dimAmber),
      labelSmall: skin.uppercaseLabel(fontSize: 10.5, color: skin.dimAmber),
    );
  }
}
