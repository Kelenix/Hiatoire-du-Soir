import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/failure.dart';
import 'speech_chunks.dart';

class ListeningRepository {
  const ListeningRepository(this._db, this._tts);

  final SupabaseClient _db;
  final FlutterTts _tts;

  static const _language = 'fr-FR';

  /// Vitesse posée pour le coucher (0,5 est la vitesse normale du téléphone) ; « lente » dans l'Espace
  /// Parents. Réglées à l'écoute le 20/11/2026 : la vitesse normale était trop rapide pour un enfant.
  static const defaultRate = .38;
  static const slowRate = .32;

  /// Voix légèrement plus grave que d'habitude : plus douce à l'oreille.
  static const _pitch = .95;

  /// Silence entre deux paragraphes, et après le titre : l'histoire respire.
  static const _pause = Duration(milliseconds: 900);

  /// Le plugin ne signale pas toujours un échec de synthèse : au-delà de ce délai, on abandonne (R7).
  static const _synthesisTimeout = Duration(seconds: 45);

  /// Voix française présente sur le téléphone. Sur Android, ses données doivent être installées :
  /// une voix « en ligne » seule échoue souvent.
  Future<bool> hasFrenchVoice() async {
    final isInstalled = Platform.isAndroid ? _tts.isLanguageInstalled(_language) : _tts.isLanguageAvailable(_language);
    return await isInstalled == true;
  }

  /// Synthétise l'histoire dans un fichier local avec la voix du téléphone (ADR-013) : le titre puis
  /// chaque paragraphe à part, réassemblés avec un silence entre eux.
  Future<String> standardAudioFile(List<String> passages, {double rate = defaultRate}) async {
    final directory = await getTemporaryDirectory();
    // Un nom par histoire : une synthèse abandonnée n'écrase jamais celle de l'histoire suivante.
    final fileName = 'histoire-${Object.hashAll(passages).toUnsigned(32)}';
    _removeOtherAudio(directory, keep: fileName);
    final name = '${directory.path}/$fileName';
    await _prepareVoice(rate);
    final parts = <String>[];
    for (final passage in passages) {
      // Un paragraphe dépasse rarement la limite d'Android ; sinon il est coupé entre deux phrases.
      for (final chunk in splitForSpeech(passage)) {
        parts.add('$name-${parts.length}.wav');
        await _synthesize(chunk, parts.last);
      }
    }
    final story = '$name.wav';
    final audio = concatenateWav([for (final part in parts) await File(part).readAsBytes()], pause: _pause);
    await File(story).writeAsBytes(audio);
    await Future.wait(parts.map((part) => File(part).delete()));
    return story;
  }

  /// La meilleure voix française du téléphone, à la vitesse et au ton du coucher.
  Future<void> _prepareVoice(double rate) async {
    await _tts.setLanguage(_language);
    final voice = bestFrenchVoice(await _tts.getVoices as List<Object?>? ?? const []);
    if (voice != null) await _tts.setVoice(voice);
    await _tts.setSpeechRate(rate);
    await _tts.setPitch(_pitch);
    await _tts.awaitSynthCompletion(true);
  }

  /// Arrête une synthèse en cours : l'enfant a quitté l'histoire.
  Future<void> stopSynthesis() async => _tts.stop();

  /// Les écoutes précédentes ne sont pas gardées : jusqu'à 25 Mo de WAV pour 10 minutes. Quelques
  /// fichiers au plus : la lecture synchrone du dossier est immédiate.
  static void _removeOtherAudio(Directory directory, {required String keep}) {
    for (final file in directory.listSync()) {
      final fileName = file.uri.pathSegments.last;
      if (fileName.startsWith('histoire-') && !fileName.startsWith(keep)) file.deleteSync();
    }
  }

  Future<void> _synthesize(String text, String path) async {
    try {
      if (await _tts.synthesizeToFile(text, path, true).timeout(_synthesisTimeout) != 1) throw Failure.unexpected;
    } on TimeoutException {
      await _tts.stop();
      throw Failure.timeout;
    }
  }

  /// Audio d'une voix apaisante (US-36) : synthétisé par le serveur à la première écoute, puis gardé.
  /// Sans histoire, l'extrait de la voix. Lève [Failure.locked] sans Premium ni Pack Voix.
  Future<Uri> premiumAudio(String voiceId, {String? storyId}) => guard(() async {
    final response = await _db.functions
        .invoke('synthesize-voice', body: {'voice_id': voiceId, 'story_id': ?storyId})
        .timeout(const Duration(seconds: 20));
    final path = (response.data as Map<String, dynamic>)['path'] as String;
    return Uri.parse(await _db.storage.from('story-audio').createSignedUrl(path, 3600));
  });

  /// Décompte l'écoute côté serveur, ou lève [Failure.locked] si elle a déjà eu lieu (US-11).
  Future<void> startListening(String storyId) =>
      guard(() => _db.rpc<void>('start_listening', params: {'p_story_id': storyId}));
}

final listeningRepositoryProvider = Provider((ref) => ListeningRepository(Supabase.instance.client, FlutterTts()));

const _qualityRank = ['very high', 'premium', 'high', 'enhanced', 'normal', 'default'];

/// Meilleure voix française installée et utilisable hors connexion (France d'abord, puis la plus
/// haute qualité) : la qualité du téléphone compte beaucoup pour une lecture douce (R7).
Map<String, String>? bestFrenchVoice(List<Object?> voices) {
  final french = [
    for (final voice in voices)
      if (voice is Map && '${voice['locale']}'.toLowerCase().startsWith('fr') && voice['network_required'] != '1')
        (name: '${voice['name']}', locale: '${voice['locale']}', quality: '${voice['quality']}'),
  ];
  int rank(({String name, String locale, String quality}) voice) {
    final quality = _qualityRank.indexOf(voice.quality);
    return (voice.locale.toLowerCase() == 'fr-fr' ? 0 : 10) + (quality < 0 ? _qualityRank.length : quality);
  }

  french.sort((a, b) => rank(a) - rank(b));
  return french.isEmpty ? null : {'name': french.first.name, 'locale': french.first.locale};
}
