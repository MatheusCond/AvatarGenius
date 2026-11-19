import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';

/// Progresso do fluxo de criação. As etapas são uma sequência de verdade,
/// por isso numeradas.
class StepIndicator extends StatelessWidget {
  const StepIndicator({super.key, required this.current, required this.labels});

  final int current;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brand = BrandColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      label: 'Etapa ${current + 1} de ${labels.length}: ${labels[current]}',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: i <= current ? brand.line : scheme.outlineVariant,
                ),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < current
                        ? brand.line
                        : i == current
                        ? scheme.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: i <= current ? Colors.transparent : scheme.outline,
                      width: 1.5,
                    ),
                  ),
                  child: i < current
                      ? Icon(Icons.check, size: 16, color: scheme.surface)
                      : Text(
                          '${i + 1}',
                          style: textTheme.labelMedium?.copyWith(
                            color: i == current
                                ? scheme.onPrimary
                                : brand.muted,
                          ),
                        ),
                ),
                if (i == current) ...[
                  const SizedBox(width: 8),
                  Text(labels[i], style: textTheme.labelMedium),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
