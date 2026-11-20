import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TextSize {
  small(18),
  medium(20),
  large(24);

  const TextSize(this.points);

  final double points;
}

/// Réglages de lecture du parent (US-18, H17), gardés sur le téléphone : non sensibles.
/// `voiceId` : voix apaisante choisie (US-36) ; nulle pour la voix du téléphone.
typedef ReadingSettings = ({bool isSlowVoice, TextSize textSize, String? voiceId});

const ReadingSettings defaultReadingSettings = (isSlowVoice: false, textSize: TextSize.medium, voiceId: null);

class ReadingSettingsController extends AsyncNotifier<ReadingSettings> {
  static const _slowVoiceKey = 'lecture.voix_lente';
  static const _textSizeKey = 'lecture.taille_texte';
  static const _voiceKey = 'lecture.voix';

  final _preferences = SharedPreferencesAsync();

  @override
  Future<ReadingSettings> build() async => (
    isSlowVoice: await _preferences.getBool(_slowVoiceKey) ?? defaultReadingSettings.isSlowVoice,
    textSize:
        TextSize.values.asNameMap()[await _preferences.getString(_textSizeKey)] ?? defaultReadingSettings.textSize,
    voiceId: await _preferences.getString(_voiceKey),
  );

  Future<void> setSlowVoice(bool isSlowVoice) async {
    await _preferences.setBool(_slowVoiceKey, isSlowVoice);
    state = AsyncData((isSlowVoice: isSlowVoice, textSize: _current.textSize, voiceId: _current.voiceId));
  }

  Future<void> setTextSize(TextSize textSize) async {
    await _preferences.setString(_textSizeKey, textSize.name);
    state = AsyncData((isSlowVoice: _current.isSlowVoice, textSize: textSize, voiceId: _current.voiceId));
  }

  Future<void> setVoice(String? voiceId) async {
    await (voiceId == null ? _preferences.remove(_voiceKey) : _preferences.setString(_voiceKey, voiceId));
    state = AsyncData((isSlowVoice: _current.isSlowVoice, textSize: _current.textSize, voiceId: voiceId));
  }

  ReadingSettings get _current => state.valueOrNull ?? defaultReadingSettings;
}

final readingSettingsProvider = AsyncNotifierProvider<ReadingSettingsController, ReadingSettings>(
  ReadingSettingsController.new,
);
