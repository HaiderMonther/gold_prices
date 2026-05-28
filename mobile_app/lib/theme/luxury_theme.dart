import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LuxuryTheme {
  // Brand Colors
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldDark = Color(0xFFB59424);
  static const Color goldLight = Color(0xFFF3E5AB);
  
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate50 = Color(0xFFF8FAFC);
  
  static const Color emerald600 = Color(0xFF059669);
  static const Color emerald50 = Color(0xFFECFDF5);
  
  static const Color rose600 = Color(0xFFE11D48);
  static const Color rose50 = Color(0xFFFFF1F2);

  // Gradients
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF3E5AB), Color(0xFFD4AF37), Color(0xFFB59424)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient getPrimaryGradient(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return LinearGradient(
      colors: [
        primary.withOpacity(0.7),
        primary,
        primary.withOpacity(0.8),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static const LinearGradient darkGradient = LinearGradient(
    colors: [slate900, Color(0xFF020617)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Card Decoration
  static BoxDecoration luxuryCard({bool isDark = false}) {
    return BoxDecoration(
      color: isDark ? slate800 : Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.04),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  // Input Field Decoration
  static InputDecoration inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: slate400, size: 20),
      suffixIcon: suffixIcon,
      hintStyle: GoogleFonts.cairo(color: slate400, fontWeight: FontWeight.bold, fontSize: 13),
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: gold, width: 2),
      ),
    );
  }

  // Helper to parse hex to Color
  static Color _parseColor(String? hexString, {Color fallback = gold}) {
    if (hexString == null || hexString.isEmpty) return fallback;
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return fallback;
    }
  }

  // App Theme Setup
  static ThemeData getThemeData({String? primaryColorHex}) {
    final dynamicGold = _parseColor(primaryColorHex);
    
    return ThemeData(
      useMaterial3: true,
      primaryColor: dynamicGold,
      scaffoldBackgroundColor: slate50,
      colorScheme: ColorScheme.fromSeed(
        seedColor: dynamicGold,
        primary: dynamicGold,
        secondary: slate900,
        surface: slate50,
      ),
      textTheme: GoogleFonts.cairoTextTheme(),
    );
  }
}
