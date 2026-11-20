import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../../core/failure.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../catalog/domain/voice.dart';
import '../../offers/data/offers_repository.dart';
import '../../parents/application/reading_settings.dart';
import '../../stories/domain/story.dart';
import '../data/listening_repository.dart';

enum ListeningStatus { ready, preparing, playing, paused, locked, noVoice, offline, failed }

/// Un seul lecteur à la fois (contrainte de just_audio_background), libéré en quittant l'histoire :
/// quitter le lecteur termine l'écoute (H5).
final audioPlayerProvider = Provider.autoDispose((ref) {
  final player = AudioPlayer();
  ref.onDispose(player.dispose);
  return player;
});

/// Voix apaisante choisie par le parent, si la famille y a droit (Premium ou Pack Voix) et si elle est
/// toujours au catalogue ; sinon nulle : voix du téléphone.
final premiumVoiceProvider = Provider<Voice?>((ref) {
  if (!(ref.watch(entitlementsProvider).valueOrNull?.canUsePremiumVoices ?? false)) return null;
  final voiceId = ref.watch(readingSettingsProvider).valueOrNull?.voiceId;
  return ref.watch(voicesProvider).valueOrNull?.where((voice) => voice.id == voiceId).firstOrNull;
});

/// Écoute d'une histoire avec la voix du téléphone ou une voix apaisante (US-10 à US-12, US-36).
class ListeningController extends AutoDisposeFamilyNotifier<ListeningStatus, Story> {
  /// L'enfant a quitté l'histoire : une préparation encore en cours ne décompte ni ne joue plus rien.
  var _isDisposed = false;

  @override
  ListeningStatus build(Story story) {
    final subscription = ref.watch(audioPlayerProvider).playerStateStream.listen(_onPlayerState);
    ref.onDispose(() {
      _isDisposed = true;
      unawaited(subscription.cancel());
    });
    return story.listensCount > 0 && !_isPremium ? ListeningStatus.locked : ListeningStatus.ready;
  }

  Future<void> toggle() async {
    final player = ref.read(audioPlayerProvider);
    switch (state) {
      case ListeningStatus.playing:
        await player.pause();
      case ListeningStatus.paused:
        unawaited(player.play());
      case ListeningStatus.ready || ListeningStatus.offline || ListeningStatus.failed:
        await _start(player);
      case ListeningStatus.preparing || ListeningStatus.locked || ListeningStatus.noVoice:
        return;
    }
  }

  /// L'audio est préparé et chargé avant de décompter l'écoute : un échec ne la consomme pas.
  Future<void> _start(AudioPlayer player) async {
    final repository = ref.read(listeningRepositoryProvider);
    final isSlowVoice = (ref.read(readingSettingsProvider).valueOrNull ?? defaultReadingSettings).isSlowVoice;
    final voice = ref.read(premiumVoiceProvider);
    final tag = MediaItem(id: arg.id, title: arg.title, album: 'Histoires du Soir');
    state = ListeningStatus.preparing;
    ref.onDispose(() => unawaited(repository.stopSynthesis()));
    try {
      final AudioSource source;
      if (voice != null) {
        source = AudioSource.uri(await repository.premiumAudio(voice.id, storyId: arg.id), tag: tag);
      } else if (await repository.hasFrenchVoice()) {
        final path = await repository.standardAudioFile(
          arg.spokenText,
          rate: isSlowVoice ? ListeningRepository.slowRate : ListeningRepository.defaultRate,
        );
        source = AudioSource.file(path, tag: tag);
      } else {
        _set(ListeningStatus.noVoice);
        return;
      }
      if (_isDisposed) return;
      // La voix du téléphone est déjà synthétisée lentement ; une voix apaisante est ralentie à la lecture.
      await player.setSpeed(voice != null && isSlowVoice ? .85 : 1);
      await player.setAudioSource(source);
      if (_isDisposed) return;
      await repository.startListening(arg.id);
      if (!_isDisposed) unawaited(player.play());
    } on Failure catch (failure) {
      _set(switch (failure) {
        Failure.locked => ListeningStatus.locked,
        Failure.offline => ListeningStatus.offline,
        _ => ListeningStatus.failed,
      });
    } on Object {
      // Synthèse, téléchargement ou lecteur en échec (R7) : on propose de réessayer.
      _set(ListeningStatus.failed);
    }
  }

  void _set(ListeningStatus status) {
    if (!_isDisposed) state = status;
  }

  bool get _isPremium => ref.read(entitlementsProvider).valueOrNull?.isPremium ?? false;

  void _onPlayerState(PlayerState player) {
    switch (player.processingState) {
      case ProcessingState.completed:
        // Gratuit : l'écoute est consommée ; Premium : réécoute possible (US-11, US-27).
        state = _isPremium ? ListeningStatus.ready : ListeningStatus.locked;
      case ProcessingState.ready when state != ListeningStatus.preparing || player.playing:
        state = player.playing ? ListeningStatus.playing : ListeningStatus.paused;
      case ProcessingState.idle when state == ListeningStatus.playing || state == ListeningStatus.paused:
        // Lecture interrompue (réseau coupé pendant une voix apaisante) : on propose de réessayer.
        state = ListeningStatus.failed;
      case _:
        return;
    }
  }
}

final listeningProvider = NotifierProvider.autoDispose.family<ListeningController, ListeningStatus, Story>(
  ListeningController.new,
);
