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

  /// Vitesse par défaut, un peu posée pour le coucher ; réglable dans l'Espace Parents (Inc-4).
  static const defaultRate = .45;
  static const slowRate = .38;

  /// Le plugin ne signale pas toujours un échec de synthèse : au-delà de ce délai, on abandonne (R7).
  static const _synthesisTimeout = Duration(seconds: 45);

  /// Voix française présente sur le téléphone. Sur Android, ses données doivent être installées :
  /// une voix « en ligne » seule échoue souvent.
  Future<bool> hasFrenchVoice() async {
    final isInstalled = Platform.isAndroid ? _tts.isLanguageInstalled(_language) : _tts.isLanguageAvailable(_language);
    return await isInstalled == true;
  }

  /// Synthétise le texte dans un fichier local avec la voix du téléphone (ADR-013), morceau par morceau
  /// au-delà de la limite d'Android, puis réassemblé en un seul fichier.
  Future<String> standardAudioFile(String text, {double rate = defaultRate}) async {
    final directory = await getTemporaryDirectory();
    // Un nom par histoire : une synthèse abandonnée n'écrase jamais celle de l'histoire suivante.
    final fileName = 'histoire-${text.hashCode.toUnsigned(32)}';
    _removeOtherAudio(directory, keep: fileName);
    final name = '${directory.path}/$fileName';
    await _tts.setLanguage(_language);
    await _tts.setSpeechRate(rate);
    await _tts.awaitSynthCompletion(true);
    final parts = <String>[];
    for (final (index, chunk) in splitForSpeech(text).indexed) {
      parts.add('$name-$index.wav');
      await _synthesize(chunk, parts.last);
    }
    if (parts.length == 1) return parts.single;
    final story = '$name.wav';
    await File(story).writeAsBytes(concatenateWav([for (final part in parts) await File(part).readAsBytes()]));
    await Future.wait(parts.map((part) => File(part).delete()));
    return story;
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
