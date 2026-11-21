/// Valeurs publiques injectées à la compilation : `--dart-define-from-file=env/<env>.json`.
/// Aucun secret ici (ADR-015).
abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// Adresse du support (US-19) et page des informations légales (US-23) ; vides tant qu'elles
  /// n'existent pas (tâches manuelles), et les entrées correspondantes restent alors masquées.
  static const supportEmail = String.fromEnvironment('SUPPORT_EMAIL');
  static const legalUrl = String.fromEnvironment('LEGAL_URL');

  /// Clés publiques RevenueCat (achats intégrés, ADR-009) ; vides tant que le compte n'existe pas.
  static const revenueCatAndroidKey = String.fromEnvironment('REVENUECAT_ANDROID_KEY');
  static const revenueCatIosKey = String.fromEnvironment('REVENUECAT_IOS_KEY');

  /// Identifiant OAuth « application Web » de Google (public), pour la connexion Google du parent
  /// (ADR-038) ; vide tant qu'il n'existe pas, et le bouton reste alors masqué.
  static const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  /// Connexion par code e-mail : à `false` tant que la production n'a pas de service d'envoi
  /// (SMTP), car le code n'arriverait jamais (ADR-040).
  static const emailCodeEnabled = bool.fromEnvironment('EMAIL_CODE_ENABLED', defaultValue: true);
}
