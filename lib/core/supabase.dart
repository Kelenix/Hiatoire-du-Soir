import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';

Future<void> initSupabase() async {
  if (AppConfig.supabaseUrl.isEmpty || AppConfig.supabasePublishableKey.isEmpty) {
    throw StateError('Configuration absente : lancer avec --dart-define-from-file=env/dev.json');
  }
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabasePublishableKey,
    authOptions: const FlutterAuthClientOptions(localStorage: SecureSessionStorage()),
  );
}

/// Range la session dans le Keychain (iOS) ou le Keystore (Android) au lieu des préférences
/// partagées utilisées par défaut (ADR-016).
class SecureSessionStorage extends LocalStorage {
  const SecureSessionStorage();

  static const _storage = FlutterSecureStorage();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: supabasePersistSessionKey);

  @override
  Future<String?> accessToken() => _storage.read(key: supabasePersistSessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: supabasePersistSessionKey, value: persistSessionString);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: supabasePersistSessionKey);
}
