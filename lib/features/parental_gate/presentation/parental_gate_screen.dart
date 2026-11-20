import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/night_scaffold.dart';
import '../../../shared/widgets/pill_buttons.dart';
import '../application/parental_gate.dart';

/// Contrôle parental (US-16, maquette C1). Réussi : on continue vers [next] ; 3 erreurs : retour enfant.
class ParentalGateScreen extends ConsumerStatefulWidget {
  const ParentalGateScreen({super.key, required this.next});

  final String next;

  @override
  ConsumerState<ParentalGateScreen> createState() => _ParentalGateScreenState();
}

class _ParentalGateScreenState extends ConsumerState<ParentalGateScreen> {
  static const _maxErrors = 3;
  static const _maxDigits = 3;

  final _random = Random();
  late var _challenge = ParentalChallenge(_random);
  var _answer = '';
  var _errors = 0;

  void _type(String digit) {
    if (_answer.length < _maxDigits) setState(() => _answer += digit);
  }

  void _erase() {
    if (_answer.isNotEmpty) setState(() => _answer = _answer.substring(0, _answer.length - 1));
  }

  void _submit() {
    if (_challenge.isAnsweredBy(_answer)) {
      ref.read(parentalGateProvider.notifier).unlock();
      context.go(widget.next);
      return;
    }
    if (++_errors >= _maxErrors) {
      context.go('/');
      return;
    }
    setState(() {
      _challenge = ParentalChallenge(_random);
      _answer = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return NightScaffold(
      title: 'Espace réservé aux parents',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            Text(_challenge.question, textAlign: TextAlign.center, style: textTheme.titleMedium),
            if (_errors > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Ce n’est pas la bonne réponse. Essai ${_errors + 1} sur $_maxErrors.',
                style: textTheme.bodySmall!.copyWith(color: AppColors.error),
              ),
            ],
            const SizedBox(height: 24),
            Semantics(
              label: 'Réponse saisie',
              value: _answer,
              child: Container(
                width: 160,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.lavender, width: 1.5),
                ),
                child: Text(_answer, style: textTheme.headlineMedium),
              ),
            ),
            const SizedBox(height: 24),
            _Keypad(onDigit: _type, onErase: _erase),
            const SizedBox(height: 24),
            MagicButton(label: 'Valider', onPressed: _answer.isEmpty ? null : _submit),
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onDigit, required this.onErase});

  final ValueChanged<String> onDigit;
  final VoidCallback onErase;

  @override
  Widget build(BuildContext context) {
    Widget key(String label, VoidCallback onTap, {String? semanticLabel}) => Padding(
      padding: const EdgeInsets.all(6),
      child: Semantics(
        button: true,
        label: semanticLabel ?? label,
        excludeSemantics: true,
        child: Material(
          color: AppColors.roundButtonFill,
          shape: const CircleBorder(side: BorderSide(color: AppColors.roundButtonBorder, width: 1.5)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox.square(
              dimension: 68,
              child: Center(child: Text(label, style: Theme.of(context).textTheme.headlineMedium)),
            ),
          ),
        ),
      ),
    );

    return Column(
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [for (final digit in row) key(digit, () => onDigit(digit))],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 80),
            key('0', () => onDigit('0')),
            key('⌫', onErase, semanticLabel: 'Effacer'),
          ],
        ),
      ],
    );
  }
}
