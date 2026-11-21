import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:histoires_du_soir/features/player/data/listening_repository.dart';
import 'package:histoires_du_soir/features/player/data/speech_chunks.dart';

/// WAV PCM 16 bits mono minimal portant [samples].
Uint8List _wav(List<int> samples) {
  final format = ByteData(16)
    ..setUint16(0, 1, Endian.little)
    ..setUint16(2, 1, Endian.little)
    ..setUint32(4, 22050, Endian.little)
    ..setUint32(8, 44100, Endian.little)
    ..setUint16(12, 2, Endian.little)
    ..setUint16(14, 16, Endian.little);
  final data = Uint8List.fromList(samples);
  final header = ByteData(20)
    ..setUint32(0, 0x46464952, Endian.little)
    ..setUint32(4, 4 + 24 + 8 + data.length, Endian.little)
    ..setUint32(8, 0x45564157, Endian.little)
    ..setUint32(12, 0x20746d66, Endian.little)
    ..setUint32(16, 16, Endian.little);
  return (BytesBuilder()
        ..add(header.buffer.asUint8List())
        ..add(format.buffer.asUint8List())
        ..add(
          (ByteData(8)
                ..setUint32(0, 0x61746164, Endian.little)
                ..setUint32(4, data.length, Endian.little))
              .buffer
              .asUint8List(),
        )
        ..add(data))
      .takeBytes();
}

void main() {
  test('les longues histoires sont coupées entre deux paragraphes, sous la limite d’Android', () {
    final paragraph = 'Il était une fois un petit renard qui regardait les étoiles. ' * 10;
    final text = List.filled(20, paragraph.trim()).join('\n\n');

    final chunks = splitForSpeech(text);

    expect(chunks.length, greaterThan(1));
    expect(chunks.every((chunk) => chunk.length <= 3500), isTrue);
    expect(chunks.join('\n\n'), text);
  });

  test('un paragraphe géant est coupé entre deux mots', () {
    final chunks = splitForSpeech('mot ' * 2000);

    expect(chunks.every((chunk) => chunk.length <= 3500 && !chunk.startsWith(' ')), isTrue);
    expect(chunks.join(' ').split(' ').where((word) => word.isNotEmpty), hasLength(2000));
  });

  test('les morceaux audio sont réassemblés en un seul fichier WAV valide', () {
    final wav = concatenateWav([
      _wav([1, 2, 3, 4]),
      _wav([5, 6]),
    ]);
    final view = ByteData.sublistView(wav);

    expect(String.fromCharCodes(wav, 0, 4), 'RIFF');
    expect(view.getUint32(4, Endian.little), wav.length - 8);
    expect(String.fromCharCodes(wav, 36, 40), 'data');
    expect(view.getUint32(40, Endian.little), 6);
    expect(wav.sublist(44), [1, 2, 3, 4, 5, 6]);
  });

  test('un silence sépare les paragraphes réassemblés', () {
    final wav = concatenateWav([
      _wav([1, 2]),
      _wav([3, 4]),
    ], pause: const Duration(milliseconds: 100));

    // 44 100 octets par seconde : 4 410 octets de silence en 100 ms.
    expect(wav.length, 44 + 2 + 4410 + 2);
    expect(wav.sublist(44, 46), [1, 2]);
    expect(wav.sublist(46, 46 + 4410).every((byte) => byte == 0), isTrue);
    expect(wav.sublist(46 + 4410), [3, 4]);
  });

  test('la meilleure voix française installée est choisie (France, qualité, hors connexion)', () {
    final voice = bestFrenchVoice([
      {'name': 'en-us-x-iol-local', 'locale': 'en-US', 'quality': 'very high', 'network_required': '0'},
      {'name': 'fr-fr-x-frc-network', 'locale': 'fr-FR', 'quality': 'very high', 'network_required': '1'},
      {'name': 'fr-ca-x-cab-local', 'locale': 'fr-CA', 'quality': 'very high', 'network_required': '0'},
      {'name': 'fr-fr-x-frb-local', 'locale': 'fr-FR', 'quality': 'normal', 'network_required': '0'},
      {'name': 'fr-fr-x-frd-local', 'locale': 'fr-FR', 'quality': 'high', 'network_required': '0'},
    ]);

    expect(voice, {'name': 'fr-fr-x-frd-local', 'locale': 'fr-FR'});
    expect(bestFrenchVoice(const []), isNull);
  });
}
