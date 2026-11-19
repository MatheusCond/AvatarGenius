import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// O elemento visual do app: um adesivo redondo com contorno de tinta e
/// sombra chapada, levemente torto, como se colado num caderno.
class Sticker extends StatelessWidget {
  const Sticker({
    super.key,
    required this.child,
    this.size = 120,
    this.tiltDegrees = 0,
    this.background,
  });

  final Widget child;
  final double size;
  final double tiltDegrees;
  final Color? background;

  /// Inclinação variada e estável por posição na grade.
  static double tiltFor(int index) =>
      const [-3.0, 2.0, -1.5, 3.0, -2.5, 1.0][index % 6];

  @override
  Widget build(BuildContext context) {
    final brand = BrandColors.of(context);
    final outline = math.max(2.5, size * 0.03);
    final shadow = math.max(3.0, size * 0.04);

    return Transform.rotate(
      angle: tiltDegrees * math.pi / 180,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              background ??
              Theme.of(context).colorScheme.surfaceContainerLowest,
          border: Border.all(color: brand.line, width: outline),
          boxShadow: [
            BoxShadow(color: brand.line, offset: Offset(shadow, shadow)),
          ],
        ),
        child: ClipOval(child: child),
      ),
    );
  }
}
