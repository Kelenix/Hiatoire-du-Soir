import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/mascot_state.dart';
import '../../../shared/widgets/night_scaffold.dart';
import '../../../shared/widgets/pill_buttons.dart';

/// « Demande à un parent » (US-28, maquette E8) : jamais de prix côté enfant.
class AskParentScreen extends StatelessWidget {
  const AskParentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return NightScaffold(
      body: Column(
        children: [
          const Expanded(
            child: MascotState(
              title: 'Oh ! C’est bien gardé par la lune.',
              message: 'Demande à un parent de venir t’aider.',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinePillButton(label: 'Je suis le parent', onPressed: () => context.push('/parents/premium')),
                TextButton(onPressed: () => context.pop(), child: const Text('Retour')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
