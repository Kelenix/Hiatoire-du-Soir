import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:histoires_du_soir/core/failure.dart';
import 'package:histoires_du_soir/features/player/data/listening_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockTts extends Mock implements FlutterTts {}

class _MockSupabase extends Mock implements SupabaseClient {}

class _TempDirectory extends Fake with MockPlatformInterfaceMixin implements PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async => Directory.systemTemp.path;
}

void main() {
  testWidgets('synthèse sans réponse du téléphone : abandon au bout de 45 s, sans blocage (R7)', (tester) async {
    PathProviderPlatform.instance = _TempDirectory();
    final tts = _MockTts();
    when(() => tts.setLanguage(any())).thenAnswer((_) async => 1);
    when(() => tts.setSpeechRate(any())).thenAnswer((_) async => 1);
    when(() => tts.setPitch(any())).thenAnswer((_) async => 1);
    when(() => tts.getVoices).thenAnswer((_) async => <Object?>[]);
    when(() => tts.awaitSynthCompletion(any())).thenAnswer((_) async => 1);
    when(() => tts.synthesizeToFile(any(), any(), any())).thenAnswer((_) => Completer<dynamic>().future);
    when(() => tts.stop()).thenAnswer((_) async => 1);

    Object? failure;
    unawaited(
      ListeningRepository(_MockSupabase(), tts).standardAudioFile(['Le renard', 'Il était une fois…']).catchError((
        Object error,
      ) {
        failure = error;
        return '';
      }),
    );
    await tester.pump(const Duration(seconds: 46));

    expect(failure, Failure.timeout);
    verify(() => tts.stop()).called(1);
  });
}
