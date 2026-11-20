import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:histoires_du_soir/core/failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<Failure> _failureOf(Object exception) async {
  try {
    await guard<void>(() async => throw exception);
  } on Failure catch (failure) {
    return failure;
  }
  throw StateError('aucune Failure levée');
}

void main() {
  test('les codes du serveur deviennent des erreurs compréhensibles', () async {
    expect(
      await _failureOf(const FunctionException(status: 403, details: {'error': 'QUOTA_REACHED'})),
      Failure.quotaReached,
    );
    expect(await _failureOf(const FunctionException(status: 403, details: {'error': 'LOCKED'})), Failure.locked);
    expect(
      await _failureOf(const FunctionException(status: 422, details: {'error': 'CONTENT_REJECTED'})),
      Failure.contentRejected,
    );
    expect(await _failureOf(const PostgrestException(message: 'CHARACTERS_LIMIT')), Failure.charactersLimit);
    expect(await _failureOf(const FunctionException(status: 500, details: 'boom')), Failure.unexpected);
  });

  test('réseau coupé, délai dépassé et erreur de base sont distingués', () async {
    expect(await _failureOf(const SocketException('hors connexion')), Failure.offline);
    expect(await _failureOf(TimeoutException('trop long')), Failure.timeout);
    expect(await _failureOf(const PostgrestException(message: 'erreur')), Failure.unexpected);
  });

  test('seuls le quota et les verrous renvoient vers un parent', () {
    expect(Failure.values.where((failure) => failure.needsParent), [Failure.quotaReached, Failure.locked]);
  });
}
