import 'package:flutter/material.dart';

/// Contenu qui défile, action principale toujours visible en bas (maquettes E3 et P5).
class BottomActionLayout extends StatelessWidget {
  const BottomActionLayout({super.key, required this.content, required this.action});

  final List<Widget> content;
  final Widget action;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: content),
        ),
      ),
      Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 20), child: action),
    ],
  );
}
