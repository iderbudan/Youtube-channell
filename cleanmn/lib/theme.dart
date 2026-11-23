import 'package:material_ui/material_ui.dart';

/// CleanMN өнгө: цэвэр, сэрүүн, тайван — гаа ногоон + тэнгэрийн цэнхэр,
/// дулаан тоорын өнгийг зөвхөн онцлох газар.
class Brand {
  static const teal = Color(0xFF14897C); // үндсэн (товч, үнэ) — цагаан текстэй уншигдана
  static const mint = Color(0xFF2BB3A2); // баннер, тод хэсэг
  static const sky = Color(0xFF5AA9E6); // баннерын градиент
  static const peach = Color(0xFFF4A261); // "Их захиалсан" тэмдэг
  static const bgLight = Color(0xFFF3F8F7); // гааны өнгөтэй цагаан дэвсгэр
  static const lineLight = Color(0xFFE2EEEB);
}

ThemeData buildTheme(Brightness b) {
  final light = b == Brightness.light;
  var scheme = ColorScheme.fromSeed(
    seedColor: Brand.mint,
    brightness: b,
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
  );
  if (light) {
    scheme = scheme.copyWith(
      primary: Brand.teal,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFD5F2EC),
      onPrimaryContainer: const Color(0xFF0B4E47),
      secondary: const Color(0xFF3E8ED0),
      secondaryContainer: const Color(0xFFDCEEFB),
      onSecondaryContainer: const Color(0xFF123F63),
      tertiary: Brand.peach,
      surface: Brand.bgLight,
      surfaceContainerLowest: Colors.white,
      outlineVariant: Brand.lineLight,
    );
  }
  final bg = light ? Brand.bgLight : scheme.surface;
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    appBarTheme: AppBarTheme(centerTitle: false, backgroundColor: bg, surfaceTintColor: Colors.transparent),
    cardTheme: CardThemeData(
      elevation: light ? 1.5 : 0,
      shadowColor: const Color(0x2214897C),
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: light ? BorderSide.none : BorderSide(color: scheme.outlineVariant),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      selectedColor: scheme.primaryContainer,
      side: BorderSide(color: scheme.outlineVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      indicatorColor: scheme.primaryContainer,
      elevation: 3,
      shadowColor: const Color(0x2214897C),
    ),
    drawerTheme: DrawerThemeData(backgroundColor: scheme.surfaceContainerLowest),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
