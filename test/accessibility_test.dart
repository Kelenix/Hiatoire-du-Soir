// Accessibilité des écrans principaux (docs/qa/test-plan.md) : contrôles intégrés de Flutter pour
// les zones tactiles (48 dp Android, 44 pt iOS), les libellés lus par TalkBack / VoiceOver et le
// contraste du texte (WCAG AA), puis texte agrandi au plafond de l'app (×1,6) sur un petit téléphone.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:histoires_du_soir/features/parental_gate/application/parental_gate.dart';
import 'package:histoires_du_soir/features/session/data/session_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'helpers.dart';

const _screens = {
  'accueil Enfant': '/',
  'thèmes': '/themes',
  'options de création': '/preparer/animaux',
  'lecture': '/histoire/histoire-1',
  'mes histoires': '/mes-histoires',
  'personnages': '/personnages',
  'accueil Parents': '/parents',
  'réglages de lecture': '/parents/parametres',
  'packs': '/parents/packs',
  'compte': '/parents/compte',
  'Premium': '/parents/premium',
};

Future<void> _open(WidgetTester tester, String location, {double textScale = 1, Size? size}) async {
  final container = await pumpApp(tester, textScale: textScale, size: size ?? const Size(390, 844));
  container.read(parentalGateProvider.notifier).unlock();
  await goTo(tester, location);
  for (var frame = 0; frame < 6; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

const _parent = User(
  id: 'parent',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-11-20',
  email: 'parent@exemple.fr',
  isAnonymous: false,
);

void main() {
  testWidgets('compte connecté : « Se déconnecter » annoncé comme un bouton à part', (tester) async {
    final semantics = tester.ensureSemantics();
    final container = await pumpApp(tester, overrides: [authUserProvider.overrideWith((ref) => Stream.value(_parent))]);
    container.read(parentalGateProvider.notifier).unlock();
    await goTo(tester, '/parents/compte');
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.getSemantics(find.text('Se déconnecter')), isSemantics(label: 'Se déconnecter', isButton: true));
    semantics.dispose();
  });

  for (final MapEntry(key: name, value: location) in _screens.entries) {
    testWidgets('$name : zones tactiles, libellés et contraste', (tester) async {
      final semantics = tester.ensureSemantics();
      await _open(tester, location);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantics.dispose();
    });

    testWidgets('$name : texte agrandi ×1,6 sur un petit téléphone, sans débordement', (tester) async {
      await _open(tester, location, textScale: 1.6, size: const Size(360, 740));

      expect(tester.takeException(), isNull);
    });
  }
}
