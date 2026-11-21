import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:histoires_du_soir/core/failure.dart';
import 'package:histoires_du_soir/features/catalog/domain/voice.dart';
import 'package:histoires_du_soir/features/player/application/listening_controller.dart';
import 'package:histoires_du_soir/features/player/data/listening_repository.dart';
import 'package:histoires_du_soir/features/stories/domain/story.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers.dart';

class _MockPlayer extends Mock implements AudioPlayer {}

/// Téléphone et serveur simulés ; [steps] garde l'ordre des appels.
class _FakeListening implements ListeningRepository {
  _FakeListening({this.hasVoice = true, this.startFailure});

  final bool hasVoice;
  final Failure? startFailure;
  final steps = <String>[];

  @override
  Future<bool> hasFrenchVoice() async {
    steps.add('voix');
    return hasVoice;
  }

  @override
  Future<String> standardAudioFile(List<String> passages, {double rate = ListeningRepository.defaultRate}) async {
    steps.add('synthèse');
    return '/tmp/histoire.wav';
  }

  @override
  Future<void> stopSynthesis() async {}

  @override
  Future<Uri> premiumAudio(String voiceId, {String? storyId}) async {
    steps.add('voix apaisante $voiceId');
    return Uri.parse('https://audio.test/$voiceId.mp3');
  }

  @override
  Future<void> startListening(String storyId) async {
    steps.add('décompte');
    if (startFailure != null) throw startFailure!;
  }
}

void main() {
  late _MockPlayer player;
  late StreamController<PlayerState> playerStates;

  setUpAll(() => registerFallbackValue(AudioSource.uri(Uri.parse('file:///fallback.wav'))));

  setUp(() {
    player = _MockPlayer();
    playerStates = StreamController<PlayerState>.broadcast();
    when(() => player.playerStateStream).thenAnswer((_) => playerStates.stream);
    when(() => player.setAudioSource(any())).thenAnswer((_) async => null);
    when(() => player.play()).thenAnswer((_) async {});
    when(() => player.setSpeed(any())).thenAnswer((_) async {});
    when(() => player.pause()).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async {});
  });

  tearDown(() => playerStates.close());

  ProviderContainer containerWith(_FakeListening listening, Story story, {Voice? voice}) {
    final container = ProviderContainer(
      overrides: [
        audioPlayerProvider.overrideWith((ref) => player),
        listeningRepositoryProvider.overrideWithValue(listening),
        premiumVoiceProvider.overrideWithValue(voice),
      ],
    );
    addTearDown(container.dispose);
    container.listen(listeningProvider(story), (_, _) {});
    return container;
  }

  test('histoire déjà écoutée : écoute verrouillée en gratuit (US-11)', () async {
    final listening = _FakeListening();
    const story = Story(id: 'h', themeId: 'animaux', durationMin: 2, title: 'T', paragraphs: ['P'], listensCount: 1);
    final container = containerWith(listening, story);

    await container.read(listeningProvider(story).notifier).toggle();

    expect(container.read(listeningProvider(story)), ListeningStatus.locked);
    expect(listening.steps, isEmpty);
  });

  test('pas de voix française : message, aucune écoute décomptée (US-12)', () async {
    final listening = _FakeListening(hasVoice: false);
    final container = containerWith(listening, testStory);

    await container.read(listeningProvider(testStory).notifier).toggle();

    expect(container.read(listeningProvider(testStory)), ListeningStatus.noVoice);
    expect(listening.steps, ['voix']);
  });

  test('écoute : synthèse avant le décompte, puis lecture (US-10, ADR-013)', () async {
    final listening = _FakeListening();
    final container = containerWith(listening, testStory);

    await container.read(listeningProvider(testStory).notifier).toggle();

    expect(listening.steps, ['voix', 'synthèse', 'décompte'], reason: 'audio chargé avant le décompte');
    verify(() => player.setAudioSource(any())).called(1);
    verify(() => player.play()).called(1);
  });

  test('voix apaisante : audio du serveur, sans voix du téléphone, puis décompte (US-36)', () async {
    final listening = _FakeListening(hasVoice: false);
    final container = containerWith(listening, testStory, voice: testVoices.first);

    await container.read(listeningProvider(testStory).notifier).toggle();

    expect(listening.steps, ['voix apaisante douce', 'décompte']);
    verify(() => player.setAudioSource(any())).called(1);
    verify(() => player.play()).called(1);
  });

  test('l’enfant quitte l’histoire pendant la préparation : rien n’est décompté', () async {
    final listening = _FakeListening();
    final container = containerWith(listening, testStory);
    final toggle = container.read(listeningProvider(testStory).notifier).toggle();
    container.dispose();
    await toggle;

    expect(listening.steps, isNot(contains('décompte')));
    verifyNever(() => player.play());
  });

  test('audio impossible à charger : réessai proposé, écoute non décomptée', () async {
    final listening = _FakeListening();
    when(() => player.setAudioSource(any())).thenThrow(PlayerException(0, 'Source error', null));
    final container = containerWith(listening, testStory);

    await container.read(listeningProvider(testStory).notifier).toggle();

    expect(container.read(listeningProvider(testStory)), ListeningStatus.failed);
    expect(listening.steps, isNot(contains('décompte')));
  });

  test('refus du serveur : verrouillée, rien n’est joué', () async {
    final listening = _FakeListening(startFailure: Failure.locked);
    final container = containerWith(listening, testStory);

    await container.read(listeningProvider(testStory).notifier).toggle();

    expect(container.read(listeningProvider(testStory)), ListeningStatus.locked);
    verifyNever(() => player.play());
  });

  test('lecture, pause, puis fin : l’écoute gratuite est consommée (H5)', () async {
    final container = containerWith(_FakeListening(), testStory);
    final controller = container.read(listeningProvider(testStory).notifier);
    await controller.toggle();

    playerStates.add(PlayerState(true, ProcessingState.ready));
    await pumpEventQueue();
    expect(container.read(listeningProvider(testStory)), ListeningStatus.playing);

    await controller.toggle();
    verify(() => player.pause()).called(1);

    playerStates.add(PlayerState(false, ProcessingState.completed));
    await pumpEventQueue();
    expect(container.read(listeningProvider(testStory)), ListeningStatus.locked);
  });
}
