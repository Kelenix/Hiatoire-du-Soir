import 'package:flutter_test/flutter_test.dart';
import 'package:histoires_du_soir/core/failure.dart';
import 'package:histoires_du_soir/features/session/data/session_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockAuth extends Mock implements GoTrueClient {}

class _MockSession extends Mock implements Session {}

class _MockClient extends Mock implements SupabaseClient {}

void main() {
  late _MockAuth auth;
  late _MockClient client;

  setUpAll(() {
    registerFallbackValue(UserAttributes());
    registerFallbackValue(OtpType.email);
  });

  setUp(() {
    auth = _MockAuth();
    client = _MockClient();
    when(() => client.auth).thenReturn(auth);
    when(() => auth.signInAnonymously()).thenAnswer((_) async => AuthResponse());
  });

  test('premier lancement : ouvre une session anonyme', () async {
    when(() => auth.currentSession).thenReturn(null);

    await SessionRepository(client).ensureSession();

    verify(() => auth.signInAnonymously()).called(1);
  });

  test('lancement suivant : réutilise la session existante', () async {
    when(() => auth.currentSession).thenReturn(_MockSession());

    await SessionRepository(client).ensureSession();

    verifyNever(() => auth.signInAnonymously());
  });

  test('compte : l’e-mail est rattaché à la session anonyme (mêmes données, ADR-010)', () async {
    when(() => auth.updateUser(any())).thenAnswer((_) async => UserResponse.fromJson({}));

    expect(await SessionRepository(client).sendEmailCode('parent@exemple.fr'), EmailCodePurpose.linkThisDevice);
    verifyNever(
      () => auth.signInWithOtp(
        email: any(named: 'email'),
        shouldCreateUser: any(named: 'shouldCreateUser'),
      ),
    );
  });

  test('compte existant (2e appareil) : connexion par code à la place', () async {
    when(
      () => auth.updateUser(any()),
    ).thenThrow(const AuthException('déjà pris', statusCode: '422', code: 'email_exists'));
    when(
      () => auth.signInWithOtp(
        email: any(named: 'email'),
        shouldCreateUser: any(named: 'shouldCreateUser'),
      ),
    ).thenAnswer((_) async {});

    expect(await SessionRepository(client).sendEmailCode('parent@exemple.fr'), EmailCodePurpose.signInExistingAccount);
    verify(() => auth.signInWithOtp(email: 'parent@exemple.fr', shouldCreateUser: false)).called(1);
  });

  test('code erroné : erreur « code invalide », pas « hors connexion »', () async {
    when(
      () => auth.verifyOTP(
        email: any(named: 'email'),
        token: any(named: 'token'),
        type: any(named: 'type'),
      ),
    ).thenThrow(const AuthException('Token has expired or is invalid', statusCode: '403', code: 'otp_expired'));

    await expectLater(
      SessionRepository(client).verifyEmailCode('parent@exemple.fr', '000000', EmailCodePurpose.linkThisDevice),
      throwsA(Failure.invalidCode),
    );
  });
}
