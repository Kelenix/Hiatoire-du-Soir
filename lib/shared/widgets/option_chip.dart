import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Une option à choisir (maquettes E3 et P5) : émoji, libellé, cadenas si l'offre ne l'inclut pas.
class OptionChip extends StatelessWidget {
  const OptionChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.emoji,
    this.isLocked = false,
  });

  final String label;
  final String? emoji;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      avatar: isLocked
          ? const Icon(Icons.lock_rounded, size: 18, color: AppColors.gold, semanticLabel: 'verrouillé')
          : null,
      label: Text(emoji == null ? label : '$emoji  $label'),
      selected: isSelected,
      onSelected: (_) => onTap(),
    );
  }
}

/// Liste d'options qui passe à la ligne.
class OptionWrap extends StatelessWidget {
  const OptionWrap({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: children);
}

/// Titre de rubrique, annoncé comme tel par les lecteurs d'écran.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Semantics(header: true, child: Text(text, style: Theme.of(context).textTheme.titleMedium)),
  );
}
