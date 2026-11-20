import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/pill_buttons.dart';

/// Achat réservé à un compte parent : abonnement et crédits ne se perdent jamais (US-25, US-34, ADR-010).
class AccountFirst extends StatelessWidget {
  const AccountFirst({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 16),
        MagicButton(label: 'Créer mon compte', onPressed: () => context.push('/parents/compte')),
      ],
    );
  }
}
