import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme/app_theme.dart';
import 'features/parental_gate/application/parental_gate.dart';
import 'features/session/presentation/session_gate.dart';

class HistoiresDuSoirApp extends ConsumerStatefulWidget {
  const HistoiresDuSoirApp({super.key});

  @override
  ConsumerState<HistoiresDuSoirApp> createState() => _HistoiresDuSoirAppState();
}

class _HistoiresDuSoirAppState extends ConsumerState<HistoiresDuSoirApp> {
  /// H22 : dès que l'app passe en arrière-plan, l'Espace Parents se referme et l'enfant retrouve
  /// son espace au retour.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onHide: _closeParentsSpace);
  }

  void _closeParentsSpace() {
    ref.read(parentalGateProvider.notifier).lock();
    final router = ref.read(routerProvider);
    final path = router.state.uri.path; // écran du dessus, y compris ceux ouverts par push
    if (path.startsWith('/parents') || path.startsWith('/controle-parental')) router.go('/');
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Histoires du Soir',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: ref.watch(routerProvider),
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // Tailles de texte du téléphone respectées, plafonnées pour ne pas casser les écrans.
      builder: (context, child) =>
          MediaQuery.withClampedTextScaling(maxScaleFactor: 1.6, child: SessionGate(child: child!)),
    );
  }
}
