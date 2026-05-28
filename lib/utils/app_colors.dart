import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0F172A);
  static const Color card = Color(0xFF1E293B);
  static const Color cardElevated = Color(0xFF243044);
  static const Color primary = Color(0xFF8B5CF6);
  static const Color accent = Color(0xFF06B6D4);
  static const Color success = Color(0xFF22C55E);
  static const Color danger = Color(0xFFEF4444);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);

  static const LinearGradient appGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient softGradient = LinearGradient(
    colors: [Color(0xFF1D4ED8), primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
