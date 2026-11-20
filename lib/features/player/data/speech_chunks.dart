import 'dart:math';
import 'dart:typed_data';

/// Android refuse de synthétiser plus de 4 000 caractères d'un coup : les histoires de 5 et 10 minutes
/// sont lues en morceaux, coupés entre deux paragraphes (ou, à défaut, entre deux mots).
List<String> splitForSpeech(String text, {int maxLength = 3500}) {
  final chunks = <String>[];
  var current = '';
  for (var paragraph in text.split('\n\n')) {
    while (paragraph.length > maxLength) {
      final cut = paragraph.lastIndexOf(' ', maxLength);
      final end = cut > 0 ? cut : maxLength;
      chunks.add(paragraph.substring(0, end));
      paragraph = paragraph.substring(end).trimLeft();
    }
    if (current.isNotEmpty && current.length + 2 + paragraph.length > maxLength) {
      chunks.add(current);
      current = '';
    }
    current = current.isEmpty ? paragraph : '$current\n\n$paragraph';
  }
  if (current.isNotEmpty) chunks.add(current);
  return chunks;
}

/// Assemble des fichiers WAV de même format (même voix, même réglage) en un seul fichier.
Uint8List concatenateWav(List<Uint8List> files) {
  Uint8List? format;
  final samples = BytesBuilder(copy: false);
  for (final file in files) {
    final view = ByteData.sublistView(file);
    var offset = 12; // « RIFF », taille, « WAVE »
    while (offset + 8 <= file.length) {
      final id = String.fromCharCodes(file, offset, offset + 4);
      final size = view.getUint32(offset + 4, Endian.little);
      final body = Uint8List.sublistView(file, offset + 8, min(offset + 8 + size, file.length));
      if (id == 'fmt ') format ??= body;
      if (id == 'data') samples.add(body);
      offset += 8 + size + size % 2;
    }
  }
  final data = samples.takeBytes();
  final header = ByteData(20)
    ..setUint32(0, 0x46464952, Endian.little) // RIFF
    ..setUint32(4, 4 + 8 + format!.length + 8 + data.length, Endian.little)
    ..setUint32(8, 0x45564157, Endian.little) // WAVE
    ..setUint32(12, 0x20746d66, Endian.little) // « fmt  »
    ..setUint32(16, format.length, Endian.little);
  final output = BytesBuilder(copy: false)
    ..add(header.buffer.asUint8List(0, 20))
    ..add(format)
    ..add(
      (ByteData(8)
            ..setUint32(0, 0x61746164, Endian.little) // data
            ..setUint32(4, data.length, Endian.little))
          .buffer
          .asUint8List(),
    )
    ..add(data);
  return output.takeBytes();
}
