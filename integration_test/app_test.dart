// Parcours du soir de bout en bout, sur un émulateur ou un téléphone, contre le Supabase local
// (docs/qa/test-plan.md) : l'app réelle, le vrai serveur et une vraie histoire écrite par Claude.
// Mesure aussi la fluidité des écrans qui défilent (docs/performance.md).
//
// flutter drive --profile --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart \
//   --dart-define-from-file=env/dev.json
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:histoires_du_soir/main.dart' as app;
import 'package:integration_test/integration_test.dart';

/// Attend un élément sans figer le temps : création d'histoire, réponses du serveur.
Future<void> _waitFor(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 20)}) async {
  final deadline = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(deadline)) throw TestFailure('Introuvable après ${timeout.inSeconds} s : $finder');
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// Touche un élément après l'avoir ramené à l'écran (les mesures font défiler les listes).
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await Future<void>.delayed(const Duration(milliseconds: 500));
  await tester.tap(finder);
}

/// Trois glissés du doigt vers le bas puis trois vers le haut, dessinés comme dans l'app (images
/// réellement produites) ; la liste revient à son début.
Future<void> _scroll(WidgetTester tester, double distance) async {
  for (final direction in [-1, 1]) {
    for (var swipe = 0; swipe < 3; swipe++) {
      await tester.fling(find.byType(Scrollable).first, Offset(0, direction * distance), 2000);
      await Future<void>.delayed(const Duration(milliseconds: 1200));
    }
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('soir type : accueil, thème, histoire créée, défilement, cœur', (tester) async {
    await app.main();
    await _waitFor(tester, find.text('Créer une histoire'));

    await tester.tap(find.text('Créer une histoire'));
    await _waitFor(tester, find.bySemanticsLabel('Animaux'));
    await binding.watchPerformance(() => _scroll(tester, 500), reportKey: 'themes');

    await _tap(tester, find.bySemanticsLabel('Animaux'));
    await _waitFor(tester, find.text('Créer l’histoire'));
    await _tap(tester, find.text('Créer l’histoire'));
    await _waitFor(tester, find.bySemanticsLabel('Écouter l’histoire'), timeout: const Duration(seconds: 90));

    await binding.watchPerformance(() => _scroll(tester, 600), reportKey: 'histoire');

    // Le cœur passe par le serveur, puis on le retire pour laisser la bibliothèque comme avant.
    await _tap(tester, find.bySemanticsLabel('Garder cette histoire'));
    await _waitFor(tester, find.bySemanticsLabel('Retirer de mes histoires'));
    await _tap(tester, find.bySemanticsLabel('Retirer de mes histoires'));
    await _waitFor(tester, find.bySemanticsLabel('Garder cette histoire'));
  });
}
