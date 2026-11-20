import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_images.dart';
import '../../../shared/widgets/mascot_state.dart';
import '../../../shared/widgets/night_scaffold.dart';
import '../application/session_provider.dart';

/// N'affiche l'app qu'une fois la session prête ; sinon attente ou écran hors connexion (NF-06).
class SessionGate extends ConsumerWidget {
  const SessionGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(sessionProvider)
        .when(
          data: (_) => child,
          loading: () => const NightScaffold(
            hasAppBar: false,
            body: Center(child: Image(image: AssetImage(AppImages.mascot), width: 160)),
          ),
          error: (_, _) => NightScaffold(
            hasAppBar: false,
            body: MascotState(
              title: 'Le ciel est nuageux ce soir…',
              message: 'Il faut une connexion Internet pour continuer. Réessaie dans un instant.',
              actionLabel: 'Réessayer',
              onAction: () => ref.invalidate(sessionProvider),
            ),
          ),
        );
  }
}
