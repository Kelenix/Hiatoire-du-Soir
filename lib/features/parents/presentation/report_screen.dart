import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/failure.dart';
import '../../../shared/widgets/night_scaffold.dart';
import '../../../shared/widgets/pill_buttons.dart';
import '../../stories/application/favorites_providers.dart';
import '../../stories/application/story_providers.dart';
import '../../stories/data/story_repository.dart';

/// Signalement d'une histoire par un parent (US-22, maquette P9).
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key, required this.storyId});

  final String storyId;

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final _comment = TextEditingController();
  ReportReason? _reason;
  var _isSending = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSending = true);
    try {
      await ref.read(storyRepositoryProvider).report(widget.storyId, _reason!, _comment.text);
      ref
        ..invalidate(latestStoryProvider)
        ..invalidate(favoritesProvider);
      messenger.showSnackBar(const SnackBar(content: Text('Merci. L’histoire est retirée et sera analysée.')));
      if (mounted) context.go('/');
    } on Failure {
      messenger.showSnackBar(const SnackBar(content: Text('Le signalement n’a pas pu être envoyé. Réessayez.')));
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return NightScaffold(
      title: 'Signaler l’histoire',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Pourquoi cette histoire ne convient-elle pas ?', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          RadioGroup<ReportReason>(
            groupValue: _reason,
            onChanged: (reason) => setState(() => _reason = reason),
            child: Column(
              children: [
                for (final reason in ReportReason.values)
                  RadioListTile<ReportReason>(
                    value: reason,
                    title: Text(reason.label, style: textTheme.bodyLarge),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _comment,
            maxLength: 500,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Commentaire (facultatif)'),
          ),
          const SizedBox(height: 8),
          Text(
            'L’histoire sera retirée de l’app. Le signalement ne contient ni prénom ni information sur votre compte.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          MagicButton(label: 'Envoyer le signalement', onPressed: _reason == null || _isSending ? null : _send),
        ],
      ),
    );
  }
}
