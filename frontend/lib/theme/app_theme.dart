import 'package:flutter/material.dart';

class AppTheme {
  // ── Warna Utama ──────────────────────────────────────────────────
  static const Color primary = Color(0xFF1A237E);
  static const Color secondary = Color(0xFF283593);
  static const Color accent = Color(0xFF5C6BC0);

  static const Color income = Color(0xFF2E7D32);
  static const Color expense = Color(0xFFC62828);
  static const Color debt = Color(0xFFE65100);
  static const Color budget = Color(0xFF6A1B9A);
  static const Color neutral = Color(0xFF37474F);

  static const Color bgLight = Color(0xFFF5F7FF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE8EAF6);

  // ── Text Styles ──────────────────────────────────────────────────
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: primary,
    letterSpacing: -0.5,
  );
  static const TextStyle heading2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: primary,
  );
  static const TextStyle heading3 = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: neutral,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: neutral,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Colors.grey,
  );
  static const TextStyle amount = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  // ── Format Rupiah ────────────────────────────────────────────────
  static String formatRupiah(dynamic value) {
    final num = double.tryParse(value.toString()) ?? 0;
    if (num >= 1000000000) {
      return "Rp ${(num / 1000000000).toStringAsFixed(1)} M";
    } else if (num >= 1000000) {
      return "Rp ${(num / 1000000).toStringAsFixed(1)} Jt";
    } else if (num >= 1000) {
      return "Rp ${(num / 1000).toStringAsFixed(0)} Rb";
    }
    return "Rp ${num.toStringAsFixed(0)}";
  }

  static String formatRupiahFull(dynamic value) {
    final num = double.tryParse(value.toString()) ?? 0;
    final str = num.toStringAsFixed(0);
    final result = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) result.write('.');
      result.write(str[i]);
      count++;
    }
    return "Rp ${result.toString().split('').reversed.join()}";
  }

  // ── ThemeData ────────────────────────────────────────────────────
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: bgLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
      ),

      // FIX: CardTheme → CardThemeData
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: divider, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
