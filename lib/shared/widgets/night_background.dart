import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Fond nuit du kit : bleu nuit, halos violets dans les coins, étoiles qui scintillent.
/// Sans étoiles derrière un long texte, pour la lisibilité.
class NightBackground extends StatelessWidget {
  const NightBackground({super.key, required this.child, this.hasStars = true});

  final Widget child;
  final bool hasStars;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.night,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _Halo(Alignment(-1.4, -1.2)),
          const _Halo(Alignment(-1.4, 1.3)),
          const _Halo(Alignment(1.4, 1.3)),
          if (hasStars) const _TwinklingStars(),
          child,
        ],
      ),
    );
  }
}

class _Halo extends StatelessWidget {
  const _Halo(this.center);

  final Alignment center;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: center,
          radius: .9,
          colors: [AppColors.halo.withValues(alpha: .55), AppColors.halo.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class _TwinklingStars extends StatefulWidget {
  const _TwinklingStars();

  @override
  State<_TwinklingStars> createState() => _TwinklingStarsState();
}

class _TwinklingStarsState extends State<_TwinklingStars> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // « Réduire les animations » du téléphone : étoiles fixes.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Calque à part : le scintillement redessine les étoiles seules, pas l'écran au-dessus
  /// (docs/performance.md).
  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(child: CustomPaint(painter: _StarsPainter(_controller))),
    );
  }
}

class _Star {
  _Star(Random random)
    : position = Offset(random.nextDouble(), random.nextDouble()),
      radius = .6 + random.nextDouble() * 1.4,
      phase = random.nextDouble(),
      isSparkle = random.nextDouble() < .12;

  final Offset position;
  final double radius;
  final double phase;
  final bool isSparkle;
}

class _StarsPainter extends CustomPainter {
  _StarsPainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;
  static final _stars = List.generate(46, (_) => _Star(_random));
  static final _random = Random(7);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final star in _stars) {
      final glow = .5 + .5 * sin(2 * pi * (animation.value + star.phase));
      final center = Offset(star.position.dx * size.width, star.position.dy * size.height);
      paint.color = (star.isSparkle ? AppColors.gold : AppColors.cream).withValues(alpha: .2 + .6 * glow);
      if (star.isSparkle) {
        canvas.drawPath(_sparkle(center, 4 + star.radius * 2), paint);
      } else {
        canvas.drawCircle(center, star.radius, paint);
      }
    }
  }

  /// Étoile à quatre branches du kit (« scintillements »).
  Path _sparkle(Offset center, double size) {
    final inner = size * .22;
    return Path()
      ..moveTo(center.dx, center.dy - size)
      ..quadraticBezierTo(center.dx + inner, center.dy - inner, center.dx + size, center.dy)
      ..quadraticBezierTo(center.dx + inner, center.dy + inner, center.dx, center.dy + size)
      ..quadraticBezierTo(center.dx - inner, center.dy + inner, center.dx - size, center.dy)
      ..quadraticBezierTo(center.dx - inner, center.dy - inner, center.dx, center.dy - size)
      ..close();
  }

  @override
  bool shouldRepaint(_StarsPainter oldDelegate) => false;
}
