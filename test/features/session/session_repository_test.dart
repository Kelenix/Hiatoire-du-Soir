import 'package:flutter_test/flutter_test.dart';
import 'package:histoires_du_soir/core/failure.dart';
import 'package:histoires_du_soir/features/session/data/google_identity.dart';
import 'package:histoires_du_soir/features/session/data/session_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockAuth extends Mock implements GoTrueClient {}

class _MockSession extends Mock implements Session {}

class _MockClient extends Mock implements SupabaseClient {}

/// Fenêtre de choix du compte Google simulée : [token] nul = le parent ferme la fenêtre.
class _FakeGoogle implements GoogleIdentity {
  String? token = 'jeton-google';
  var signOuts = 0;

  @override
  bool get isAvailable => true;

  @override
  Future<String?> idToken() async => token;

  @override
  Future<void> signOut() async => signOuts++;
}

void main() {
  late _MockAuth auth;
  late _MockClient client;
  late _FakeGoogle google;

  setUpAll(() {
    registerFallbackValue(UserAttributes());
    registerFallbackValue(OtpType.email);
    registerFallbackValue(OAuthProvider.google);
    registerFallbackValue(SignOutScope.local);
  });

  setUp(() {
    auth = _MockAuth();
    client = _MockClient();
    google = _FakeGoogle();
    when(() => client.auth).thenReturn(auth);
    when(() => auth.signInAnonymously()).thenAnswer((_) async => AuthResponse());
  });

  test('premier lancement : ouvre une session anonyme', () async {
    when(() => auth.currentSession).thenReturn(null);

    await SessionRepository(client, google).ensureSession();

    verify(() => auth.signInAnonymously()).called(1);
  });

  test('lancement suivant : réutilise la session existante', () async {
    when(() => auth.currentSession).thenReturn(_MockSession());

    await SessionRepository(client, google).ensureSession();

    verifyNever(() => auth.signInAnonymously());
  });

  test('compte : l’e-mail est rattaché à la session anonyme (mêmes données, ADR-010)', () async {
    when(() => auth.updateUser(any())).thenAnswer((_) async => UserResponse.fromJson({}));

    expect(await SessionRepository(client, google).sendEmailCode('parent@exemple.fr'), EmailCodePurpose.linkThisDevice);
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

    expect(
      await SessionRepository(client, google).sendEmailCode('parent@exemple.fr'),
      EmailCodePurpose.signInExistingAccount,
    );
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
      SessionRepository(client, google).verifyEmailCode('parent@exemple.fr', '000000', EmailCodePurpose.linkThisDevice),
      throwsA(Failure.invalidCode),
    );
  });

  group('connexion Google (ADR-038)', () {
    Future<AuthResponse> link() => auth.linkIdentityWithIdToken(
      provider: any(named: 'provider'),
      idToken: any(named: 'idToken'),
    );
    Future<AuthResponse> signIn() => auth.signInWithIdToken(
      provider: any(named: 'provider'),
      idToken: any(named: 'idToken'),
    );

    test('le compte Google est rattaché à la session anonyme (mêmes données)', () async {
      when(link).thenAnswer((_) async => AuthResponse());

      expect(await SessionRepository(client, google).signInWithGoogle(), isTrue);
      verify(() => auth.linkIdentityWithIdToken(provider: OAuthProvider.google, idToken: 'jeton-google')).called(1);
      verifyNever(signIn);
    });

    test('compte Google déjà lié à une famille (2e appareil) : connexion à ce compte', () async {
      when(link).thenThrow(const AuthException('déjà lié', statusCode: '422', code: 'identity_already_exists'));
      when(signIn).thenAnswer((_) async => AuthResponse());

      expect(await SessionRepository(client, google).signInWithGoogle(), isTrue);
      verify(() => auth.signInWithIdToken(provider: OAuthProvider.google, idToken: 'jeton-google')).called(1);
    });

    test('fenêtre de Google fermée : rien ne change', () async {
      google.token = null;

      expect(await SessionRepository(client, google).signInWithGoogle(), isFalse);
      verifyNever(link);
      verifyNever(signIn);
    });

    test('déconnexion : le prochain parent choisit de nouveau son compte Google', () async {
      when(() => auth.signOut(scope: any(named: 'scope'))).thenAnswer((_) async {});

      await SessionRepository(client, google).signOut();
      expect(google.signOuts, 1);
    });
  });
}
