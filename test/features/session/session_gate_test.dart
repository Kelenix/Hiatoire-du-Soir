import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:histoires_du_soir/core/theme/app_theme.dart';
import 'package:histoires_du_soir/features/session/application/session_provider.dart';
import 'package:histoires_du_soir/features/session/presentation/session_gate.dart';

Widget _gate(Future<void> Function() session) {
  return ProviderScope(
    overrides: [sessionProvider.overrideWith((ref) => session())],
    child: MaterialApp(
      theme: buildAppTheme(),
      home: const SessionGate(child: Text('app prête')),
    ),
  );
}

void main() {
  testWidgets("affiche l'app quand la session est prête", (tester) async {
    await tester.pumpWidget(_gate(() async {}));
    await tester.pump();

    expect(find.text('app prête'), findsOneWidget);
  });

  testWidgets('sans connexion : message doux et bouton Réessayer (NF-06)', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      _gate(() async {
        attempts++;
        throw Exception('hors connexion');
      }),
    );
    await tester.pump();

    expect(find.text('app prête'), findsNothing);
    expect(find.text('Réessayer'), findsOneWidget);

    await tester.tap(find.text('Réessayer'));
    await tester.pump();

    expect(attempts, 2);
  });
}
