import 'package:flutter/material.dart';

import 'night_background.dart';

/// Écran type de l'app : fond nuit, zone sûre, barre de titre transparente avec retour automatique.
class NightScaffold extends StatelessWidget {
  const NightScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.hasAppBar = true,
    this.hasStars = true,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final bool hasAppBar;
  final bool hasStars;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: hasAppBar ? AppBar(title: title == null ? null : Text(title!), actions: actions) : null,
      body: NightBackground(
        hasStars: hasStars,
        child: SafeArea(child: body),
      ),
    );
  }
}
