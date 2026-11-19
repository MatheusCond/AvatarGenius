import 'package:material_ui/material_ui.dart';

import '../art/caricature_face.dart';
import '../theme/app_theme.dart';

/// Caricatura-símbolo do app sobre a mancha de marca-texto.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 160});

  final double size;

  @override
  Widget build(BuildContext context) {
    final brand = BrandColors.of(context);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: CaricaturePainter(
            ink: Palette.ink,
            backdrop: brand.marker,
            traits: const CaricatureTraits(
              noseSize: 1.45,
              eyeSize: 1.15,
              smile: 1.2,
              hairStyle: 2,
            ),
          ),
        ),
      ),
    );
  }
}

class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      'AvatarGenius',
      style: AppTheme.display(
        size,
      ).copyWith(color: Theme.of(context).colorScheme.onSurface),
    );
  }
}

/// Aviso fixo de que o app está no modo demo.
class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final brand = BrandColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: brand.marker,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Palette.ink, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.science_outlined, color: Palette.ink, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Palette.ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// Limita a largura do conteúdo em telas grandes (web e tablets).
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = 440});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
