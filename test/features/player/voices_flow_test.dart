import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:histoires_du_soir/features/offers/data/offers_repository.dart';
import 'package:histoires_du_soir/features/parental_gate/application/parental_gate.dart';
import 'package:histoires_du_soir/features/parents/application/reading_settings.dart';
import 'package:histoires_du_soir/features/player/application/listening_controller.dart';
import 'package:histoires_du_soir/features/player/data/listening_repository.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers.dart';

class _MockPlayer extends Mock implements AudioPlayer {}

class _MockListening extends Mock implements ListeningRepository {}

Future<void> _settle(WidgetTester tester) async {
  for (var frame = 0; frame < 6; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

const _voicePack = Entitlements(freeStoriesLeft: 3, isAnonymous: false, hasVoicePack: true);

void main() {
  setUpAll(() => registerFallbackValue(AudioSource.uri(Uri.parse('https://audio.test/fallback.mp3'))));

  testWidgets('réglages : voix apaisantes verrouillées sans Premium ni Pack Voix, extrait écoutable (US-36)', (
    tester,
  ) async {
    final player = _MockPlayer();
    final listening = _MockListening();
    when(() => player.setAudioSource(any())).thenAnswer((_) async => null);
    when(() => player.play()).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async {});
    when(
      () => listening.premiumAudio('douce', storyId: any(named: 'storyId')),
    ).thenAnswer((_) async => Uri.parse('https://audio.test/extraits/douce.mp3'));
    final container = await pumpApp(
      tester,
      overrides: [
        audioPlayerProvider.overrideWith((ref) => player),
        listeningRepositoryProvider.overrideWithValue(listening),
      ],
    );
    container.read(parentalGateProvider.notifier).unlock();
    await goTo(tester, '/parents/parametres');
    await _settle(tester);

    expect(find.text('Débloquer les voix'), findsOneWidget);
    await tester.tap(find.text('Douce'));
    await _settle(tester);
    expect(container.read(readingSettingsProvider).valueOrNull?.voiceId, isNull, reason: 'voix verrouillée');

    await tester.tap(find.byTooltip('Écouter un extrait de la voix Douce'));
    await _settle(tester);
    verify(() => listening.premiumAudio('douce')).called(1);
    verify(() => player.play()).called(1);
  });

  testWidgets('Pack Voix : voix choisie dans les réglages, reprise au lecteur de l’enfant (US-36, US-37)', (
    tester,
  ) async {
    final container = await pumpApp(tester, entitlements: () => _voicePack);
    container.read(parentalGateProvider.notifier).unlock();
    await goTo(tester, '/parents/parametres');
    await _settle(tester);

    expect(find.text('Débloquer les voix'), findsNothing);
    await tester.tap(find.text('Douce'));
    await _settle(tester);
    expect(container.read(readingSettingsProvider).valueOrNull?.voiceId, 'douce');

    await goTo(tester, '/histoire/${testStory.id}');
    await _settle(tester);
    await tester.tap(find.text('Voix : Douce'));
    await _settle(tester);
    await tester.tap(find.text('Lune'));
    await _settle(tester);

    expect(find.text('Voix : Lune'), findsOneWidget);
  });

  testWidgets('sans voix apaisantes : rien de plus au lecteur de l’enfant', (tester) async {
    await pumpApp(tester, location: '/histoire/${testStory.id}');
    await _settle(tester);

    expect(find.text('Écouter l’histoire'), findsOneWidget);
    expect(find.textContaining('Voix'), findsNothing);
  });
}
