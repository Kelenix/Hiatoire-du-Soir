import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'app.dart';
import 'core/supabase.dart';
import 'core/theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Indépendantes les unes des autres : lancées ensemble pour raccourcir le démarrage (docs/performance.md).
  // Le fond nuit passe sous les barres du système (heure en haut, navigation en bas) : sans cela,
  // Android 14 et antérieurs les peignent en noir.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
    ),
  );
  await Future.wait([
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge),
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
    // Écoute écran verrouillé, avec la notification de lecture du système (US-10).
    JustAudioBackground.init(
      androidNotificationChannelId: 'fr.histoiresdusoir.app.ecoute',
      androidNotificationChannelName: 'Écoute des histoires',
      notificationColor: AppColors.violet,
    ),
    AudioSession.instance.then((session) => session.configure(const AudioSessionConfiguration.speech())),
    initSupabase(),
  ]);
  runApp(const ProviderScope(child: HistoiresDuSoirApp()));
}
