import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Logo texte du kit : « Histoires du Soir » en Nunito Black, dégradé blanc-lavande,
/// étoile dorée et trait lumineux sous « du Soir ».
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.fontSize = 44});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.displayLarge!.copyWith(fontSize: fontSize, height: 1, color: Colors.white);
    return Semantics(
      header: true,
      label: 'Histoires du Soir',
      child: ExcludeSemantics(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ShaderMask(
              shaderCallback: AppGradients.title.createShader,
              child: Text('Histoires\ndu Soir', textAlign: TextAlign.center, style: style),
            ),
            Positioned(
              left: fontSize * .4,
              right: -fontSize * .2,
              bottom: -fontSize * .32,
              child: CustomPaint(size: Size.fromHeight(fontSize * .3), painter: _SwooshPainter()),
            ),
            Positioned(
              right: -fontSize * .55,
              bottom: -fontSize * .2,
              child: Icon(
                Icons.star_rounded,
                color: AppColors.gold,
                size: fontSize * .7,
                shadows: [Shadow(color: AppColors.gold.withValues(alpha: .7), blurRadius: 14)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwooshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * .9)
      ..quadraticBezierTo(size.width * .55, size.height * .95, size.width * .92, size.height * .1);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [AppColors.lavender.withValues(alpha: 0), AppColors.lavender, AppColors.gold],
        stops: const [0, .5, 1],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SwooshPainter oldDelegate) => false;
}
