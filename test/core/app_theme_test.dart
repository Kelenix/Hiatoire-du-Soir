import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:histoires_du_soir/core/theme/app_theme.dart';

void main() {
  test('le thème reprend les couleurs officielles du brand kit', () {
    final theme = buildAppTheme();

    expect(theme.scaffoldBackgroundColor, const Color(0xFF0B0B2B));
    expect(theme.colorScheme.primary, const Color(0xFF6C5CE7));
    expect(theme.colorScheme.secondary, const Color(0xFFA78BFA));
    expect(theme.colorScheme.tertiary, const Color(0xFFFFC857));
    expect(theme.brightness, Brightness.dark);
  });

  test('titres en Nunito, textes en Inter (charte §4)', () {
    final text = buildAppTheme().textTheme;

    expect(text.displayLarge!.fontFamily, 'Nunito');
    expect(text.titleMedium!.fontFamily, 'Nunito');
    expect(text.bodyLarge!.fontFamily, 'Inter');
  });
}
