import 'package:flutter/material.dart';

/// Paleta de cores da marca ONDAKA.
/// Baseada no design system usado nos mockups web (ondaka-consolidado-v3, mockup apresentação).
class AppColors {
  AppColors._(); // Impede instanciação

  // === Brand principal ===
  static const Color cyan = Color(0xFF00D4FF);
  static const Color purple = Color(0xFFA855F7);
  static const Color pink = Color(0xFFEC4899);

  // === Versões soft (para texto sobre fundo escuro) ===
  static const Color cyanSoft = Color(0xFF8FE7FF);
  static const Color purpleSoft = Color(0xFFD8B4FE);
  static const Color pinkSoft = Color(0xFFFDA4CF);

  // === Estados ===
  static const Color success = Color(0xFF10B981);
  static const Color successSoft = Color(0xFF6EE7B7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFCD34D);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFCA5A5);
  static const Color info = Color(0xFF378ADD);

  // === Fundo (dark theme) ===
  static const Color bgDark = Color(0xFF0A0A1A);
  static const Color surface = Color(0xFF141428);
  static const Color surfaceHi = Color(0xFF1A1A30);
  static const Color border = Color(0x1AFFFFFF); // white @ 10%
  static const Color borderHi = Color(0x33FFFFFF); // white @ 20%

  // === Texto ===
  static const Color textMain = Color(0xFFF5F5F7);
  static const Color textMuted = Color(0xB3FFFFFF); // white @ 70%
  static const Color textFaint = Color(0x80FFFFFF); // white @ 50%

  // === Gradientes (usam as brand principais) ===
  static const LinearGradient brandGradient = LinearGradient(
    colors: [cyan, purple, pink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient brandGradientHorizontal = LinearGradient(
    colors: [cyan, purple, pink],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
