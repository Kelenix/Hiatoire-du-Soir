import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_images.dart';
import '../../../core/failure.dart';
import '../../../shared/widgets/mascot_state.dart';
import '../../../shared/widgets/night_scaffold.dart';
import '../application/story_providers.dart';
import '../data/story_repository.dart';
import '../domain/story.dart';

/// Création en cours (US-05, US-06, maquette E4).
class CreatingScreen extends ConsumerStatefulWidget {
  const CreatingScreen({super.key, required this.themeId, this.options = defaultStoryOptions});

  final String themeId;
  final StoryOptions options;

  @override
  ConsumerState<CreatingScreen> createState() => _CreatingScreenState();
}

class _CreatingScreenState extends ConsumerState<CreatingScreen> {
  late final StoryRequest _request = (requestId: newRequestId(), themeId: widget.themeId, options: widget.options);

  @override
  Widget build(BuildContext context) {
    final creation = storyCreationProvider(_request);
    ref.listen(creation, (_, next) {
      if (next case AsyncData(:final value)) context.go('/histoire/${value.id}');
      if (next case AsyncError(error: Failure(needsParent: true))) context.pushReplacement('/demande-parent');
    });
    return NightScaffold(
      body: ref
          .watch(creation)
          // Pendant « Réessayer », l'animation remplace l'erreur précédente.
          .maybeWhen(
            skipLoadingOnRefresh: false,
            error: (error, _) => _CreationError(
              failure: error is Failure ? error : Failure.unexpected,
              onRetry: () => ref.invalidate(creation),
            ),
            orElse: () => const _CreatingAnimation(),
          ),
    );
  }
}

class _CreationError extends StatelessWidget {
  const _CreationError({required this.failure, required this.onRetry});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final (title, message) = switch (failure) {
      Failure.offline => ('Le ciel est nuageux ce soir…', 'Il faut une connexion Internet pour créer une histoire.'),
      Failure.contentRejected => ('Le renard recommence…', 'Cette histoire n’était pas assez douce.'),
      Failure.abuseLimit => ('Le renard se repose…', 'Beaucoup d’histoires aujourd’hui ! Reviens demain.'),
      _ => ('L’histoire s’est égarée…', 'Le renard n’a pas réussi à l’écrire cette fois-ci.'),
    };
    return MascotState(
      title: title,
      message: '$message Réessaie : rien n’a été décompté.',
      actionLabel: 'Réessayer',
      onAction: onRetry,
    );
  }
}

/// Mascotte qui respire et phrases rassurantes pendant l'écriture.
class _CreatingAnimation extends StatefulWidget {
  const _CreatingAnimation();

  @override
  State<_CreatingAnimation> createState() => _CreatingAnimationState();
}

class _CreatingAnimationState extends State<_CreatingAnimation> with SingleTickerProviderStateMixin {
  static const _sentences = [
    'Le renard prend sa plus belle plume…',
    'Les étoiles soufflent des idées…',
    'La lune relit chaque mot…',
    'Encore un instant, l’histoire arrive…',
  ];

  late final _breath = AnimationController(vsync: this, duration: const Duration(seconds: 2));
  late final Timer _timer;
  var _sentence = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => setState(() => _sentence = (_sentence + 1) % _sentences.length),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _breath.stop();
    } else if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: Tween(begin: .94, end: 1.04).animate(CurvedAnimation(parent: _breath, curve: Curves.easeInOut)),
            child: Image.asset(AppImages.mascot, width: 200, excludeFromSemantics: true),
          ),
          const SizedBox(height: 32),
          Semantics(
            liveRegion: true,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                _sentences[_sentence],
                key: ValueKey(_sentence),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
