import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Déverrouillage de l'Espace Parents, en mémoire seulement (architecture §4) : 5 minutes,
/// effacé dès que l'app passe en arrière-plan (H22).
class ParentalGate extends Notifier<DateTime?> {
  static const validity = Duration(minutes: 5);

  @override
  DateTime? build() => null;

  bool get isUnlocked => state?.isAfter(DateTime.now()) ?? false;

  void unlock() => state = DateTime.now().add(validity);

  void lock() => state = null;
}

final parentalGateProvider = NotifierProvider<ParentalGate, DateTime?>(ParentalGate.new);

/// Addition écrite en toutes lettres, infaisable pour un enfant de 3 à 8 ans (US-16).
class ParentalChallenge {
  ParentalChallenge(Random random) : left = 21 + random.nextInt(29), right = 11 + random.nextInt(9);

  final int left;
  final int right;

  String get question => 'Combien font « ${frenchNumber(left)} plus ${frenchNumber(right)} » ?';

  bool isAnsweredBy(String answer) => int.tryParse(answer) == left + right;
}

const _units = ['', 'un', 'deux', 'trois', 'quatre', 'cinq', 'six', 'sept', 'huit', 'neuf'];
const _teens = ['dix', 'onze', 'douze', 'treize', 'quatorze', 'quinze', 'seize', 'dix-sept', 'dix-huit', 'dix-neuf'];
const _tens = ['', '', 'vingt', 'trente', 'quarante', 'cinquante', 'soixante'];

/// Nombre de 1 à 69 en toutes lettres (orthographe traditionnelle : « vingt et un », « trente-deux »).
String frenchNumber(int number) {
  assert(number >= 1 && number < 70, 'nombre hors de la plage du défi');
  if (number < 10) return _units[number];
  if (number < 20) return _teens[number - 10];
  final (ten, unit) = (number ~/ 10, number % 10);
  return switch (unit) {
    0 => _tens[ten],
    1 => '${_tens[ten]} et un',
    _ => '${_tens[ten]}-${_units[unit]}',
  };
}
