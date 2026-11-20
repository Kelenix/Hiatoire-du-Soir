import 'package:flutter/painting.dart';

/// Couleurs de la charte (`docs/design/charte-graphique.md` §2 et §3).
/// Un seul thème, fond nuit (ADR-012) : les écrans lisent ces jetons, jamais de valeur en dur.
abstract final class AppColors {
  // Couleurs officielles du kit.
  static const night = Color(0xFF0B0B2B);
  static const violet = Color(0xFF6C5CE7);
  static const lavender = Color(0xFFA78BFA);
  static const gold = Color(0xFFFFC857);
  static const cream = Color(0xFFFFF8E6);

  // Couleurs mesurées sur le kit.
  static const surface = Color(0xFF16143C);
  static const cardBorder = Color(0xFF2A1C5E);
  static const halo = Color(0xFF6929C2);
  static const textPrimary = Color(0xFFF7F6FF);
  static const textSecondary = Color(0xFFB4AED0);
  static const slogan = Color(0xFFE8E4FF);
  static const outlineButton = Color(0xFFAA90CB);
  static const tileTop = Color(0xFF673EB5);
  static const tileBottom = Color(0xFF5434A3);
  static const tileBorder = Color(0xFF2B136B);
  static const roundButtonFill = Color(0xFF442F86);
  static const roundButtonBorder = Color(0xFFAF8CE3);
  static const heart = Color(0xFFF67BBE);

  // Dérivée, absente du kit : erreurs des formulaires parents uniquement.
  static const error = Color(0xFFFF8FA3);
}

abstract final class AppGradients {
  /// Bouton principal, de gauche à droite.
  static const magic = LinearGradient(
    colors: [
      Color(0xFF8873FC),
      Color(0xFF7856FB),
      Color(0xFF814CFF),
      Color(0xFF9A4EEB),
      Color(0xFFC26BCB),
      Color(0xFFDD89A6),
      Color(0xFFF5A583),
      Color(0xFFFEBB77),
    ],
    stops: [0, .2, .4, .55, .72, .82, .92, 1],
  );

  static const title = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFEDE9FF), Color(0xFFDED6FB)],
  );

  static const tile = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.tileTop, AppColors.tileBottom],
  );
}
