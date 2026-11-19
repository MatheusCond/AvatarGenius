import 'package:material_ui/material_ui.dart';

/// Paleta "bloco do caricaturista": papel frio, tinta índigo, caneta
/// cobalto e marca-texto amarelo.
abstract final class Palette {
  static const paper = Color(0xFFF7F8FB);
  static const ink = Color(0xFF1B1F3B);
  static const cobalt = Color(0xFF2F4BFF);
  static const marker = Color(0xFFFFD23F);
  static const blush = Color(0xFFFF7A8A);
  static const mist = Color(0xFFE3E6F2);
  static const danger = Color(0xFFC8243A);

  // Modo escuro: a página vira tinta e o traço vira papel.
  static const night = Color(0xFF14172E);
  static const nightRaised = Color(0xFF1F2342);
  static const nightLine = Color(0xFFE9EBF5);
  static const cobaltLight = Color(0xFF9AAAFF);
  static const dangerLight = Color(0xFFFF8A98);
}

/// Cores da marca que não existem no [ColorScheme].
@immutable
class BrandColors extends ThemeExtension<BrandColors> {
  const BrandColors({
    required this.line,
    required this.marker,
    required this.onMarker,
    required this.bubble,
    required this.muted,
  });

  /// Contorno dos adesivos e balões (tinta no claro, papel no escuro).
  final Color line;
  final Color marker;
  final Color onMarker;

  /// Fundo do balão do personagem.
  final Color bubble;
  final Color muted;

  static const light = BrandColors(
    line: Palette.ink,
    marker: Palette.marker,
    onMarker: Palette.ink,
    bubble: Colors.white,
    muted: Color(0xFF5A5F7D),
  );

  static const dark = BrandColors(
    line: Palette.nightLine,
    marker: Palette.marker,
    onMarker: Palette.ink,
    bubble: Palette.nightRaised,
    muted: Color(0xFFB4B8CF),
  );

  static BrandColors of(BuildContext context) =>
      Theme.of(context).extension<BrandColors>()!;

  @override
  BrandColors copyWith({
    Color? line,
    Color? marker,
    Color? onMarker,
    Color? bubble,
    Color? muted,
  }) {
    return BrandColors(
      line: line ?? this.line,
      marker: marker ?? this.marker,
      onMarker: onMarker ?? this.onMarker,
      bubble: bubble ?? this.bubble,
      muted: muted ?? this.muted,
    );
  }

  @override
  BrandColors lerp(BrandColors? other, double t) {
    if (other == null) return this;
    return BrandColors(
      line: Color.lerp(line, other.line, t)!,
      marker: Color.lerp(marker, other.marker, t)!,
      onMarker: Color.lerp(onMarker, other.onMarker, t)!,
      bubble: Color.lerp(bubble, other.bubble, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
    );
  }
}

abstract final class AppTheme {
  static const displayFont = 'BagelFatOne';
  static const textFont = 'Figtree';

  static ThemeData light() => _build(
    const ColorScheme(
      brightness: Brightness.light,
      primary: Palette.cobalt,
      onPrimary: Colors.white,
      secondary: Palette.marker,
      onSecondary: Palette.ink,
      tertiary: Palette.blush,
      onTertiary: Palette.ink,
      error: Palette.danger,
      onError: Colors.white,
      surface: Palette.paper,
      onSurface: Palette.ink,
      surfaceContainerLowest: Colors.white,
      surfaceContainerHighest: Palette.mist,
      outline: Color(0xFF8C90AB),
      outlineVariant: Palette.mist,
    ),
    BrandColors.light,
  );

  static ThemeData dark() => _build(
    const ColorScheme(
      brightness: Brightness.dark,
      primary: Palette.cobaltLight,
      onPrimary: Palette.night,
      secondary: Palette.marker,
      onSecondary: Palette.ink,
      tertiary: Palette.blush,
      onTertiary: Palette.ink,
      error: Palette.dangerLight,
      onError: Palette.night,
      surface: Palette.night,
      onSurface: Palette.nightLine,
      surfaceContainerLowest: Palette.nightRaised,
      surfaceContainerHighest: Color(0xFF2A2F55),
      outline: Color(0xFF7D82A3),
      outlineVariant: Color(0xFF2A2F55),
    ),
    BrandColors.dark,
  );

  /// Figtree é uma fonte variável: o peso vai no eixo `wght`, além do
  /// `fontWeight`, para renderizar igual em todas as plataformas.
  static TextStyle text(double size, FontWeight weight, {double height = 1.4}) {
    return TextStyle(
      fontFamily: textFont,
      fontSize: size,
      fontWeight: weight,
      fontVariations: [FontVariation.weight(weight.value.toDouble())],
      height: height,
    );
  }

  static TextStyle display(double size, {double height = 1.05}) => TextStyle(
    fontFamily: displayFont,
    fontSize: size,
    height: height,
    letterSpacing: 0.2,
  );

  static ThemeData _build(ColorScheme scheme, BrandColors brand) {
    final textTheme = TextTheme(
      displayMedium: display(44),
      displaySmall: display(34),
      headlineMedium: display(28, height: 1.1),
      headlineSmall: display(24, height: 1.15),
      titleLarge: text(20, FontWeight.w700, height: 1.25),
      titleMedium: text(17, FontWeight.w700, height: 1.3),
      titleSmall: text(15, FontWeight.w700, height: 1.3),
      bodyLarge: text(17, FontWeight.w400, height: 1.45),
      bodyMedium: text(15, FontWeight.w400, height: 1.45),
      bodySmall: text(13, FontWeight.w500, height: 1.35),
      labelLarge: text(16, FontWeight.w700, height: 1.2),
      labelMedium: text(14, FontWeight.w600, height: 1.2),
      labelSmall: text(12, FontWeight.w600, height: 1.2),
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    final fieldRadius = BorderRadius.circular(14);
    OutlineInputBorder border(Color color, [double width = 1.5]) =>
        OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: color, width: width),
        );

    const buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: textFont,
      textTheme: textTheme,
      extensions: [brand],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: textTheme.bodyLarge?.copyWith(color: brand.muted),
        hintStyle: textTheme.bodyLarge?.copyWith(color: brand.muted),
        border: border(scheme.outline),
        enabledBorder: border(scheme.outline),
        focusedBorder: border(scheme.primary, 2.5),
        errorBorder: border(scheme.error),
        focusedErrorBorder: border(scheme.error, 2.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: buttonShape,
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: brand.line, width: 2),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: textTheme.labelMedium,
          minimumSize: const Size(48, 48),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        extendedTextStyle: textTheme.labelLarge,
        shape: const StadiumBorder(),
      ),
      chipTheme: ChipThemeData(
        labelStyle: textTheme.labelMedium,
        side: BorderSide(color: brand.line.withValues(alpha: 0.35)),
        backgroundColor: scheme.surfaceContainerLowest,
        shape: const StadiumBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.onSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: scheme.surface),
        actionTextColor: brand.marker,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
    );
  }
}
