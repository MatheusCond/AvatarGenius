import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/chat_message.dart';

/// Balão de mensagem. O do personagem tem contorno de tinta, como balão de
/// quadrinho; o do usuário é preenchido com a cor principal.
class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message, this.onLongPress});

  final ChatMessage message;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brand = BrandColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final mine = message.fromUser;
    const r = Radius.circular(20);
    const tail = Radius.circular(4);

    final foreground = mine ? scheme.onPrimary : scheme.onSurface;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: (MediaQuery.sizeOf(context).width * 0.78).clamp(0, 520),
        ),
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            decoration: BoxDecoration(
              color: mine ? scheme.primary : brand.bubble,
              border: mine ? null : Border.all(color: brand.line, width: 2),
              borderRadius: BorderRadius.only(
                topLeft: r,
                topRight: r,
                bottomLeft: mine ? r : tail,
                bottomRight: mine ? tail : r,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: SelectableText(
                    message.text,
                    style: textTheme.bodyLarge?.copyWith(color: foreground),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatTime(message.sentAt),
                  style: textTheme.labelSmall?.copyWith(
                    color: foreground.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Indicador de "digitando" com três pontos pulsando.
class TypingBubble extends StatefulWidget {
  const TypingBubble({super.key, required this.name});

  final String name;

  @override
  State<TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<TypingBubble>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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

  @override
  Widget build(BuildContext context) {
    final brand = BrandColors.of(context);
    return Semantics(
      liveRegion: true,
      label: '${widget.name} está digitando',
      excludeSemantics: true,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: brand.bubble,
            border: Border.all(color: brand.line, width: 2),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(4),
            ),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 5),
                    child: Opacity(
                      opacity: _dotOpacity(i),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: brand.line,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _dotOpacity(int i) {
    final t = (_controller.value - i * 0.18) % 1.0;
    return t < 0.5 ? 0.3 + t * 1.4 : 1.0 - (t - 0.5) * 1.4;
  }
}

/// Campo de mensagem com botão de enviar.
class Composer extends StatelessWidget {
  const Composer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;

  /// Falso enquanto o personagem responde.
  final bool enabled;

  /// Lido na hora do envio, e não no último build, para um Enter logo após
  /// digitar não ser ignorado.
  bool get _canSend => enabled && controller.text.trim().isNotEmpty;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            // Enter envia e Shift+Enter quebra a linha (teclado físico e web).
            child: Focus(
              onKeyEvent: (node, event) {
                final isEnter =
                    event.logicalKey == LogicalKeyboardKey.enter ||
                    event.logicalKey == LogicalKeyboardKey.numpadEnter;
                if (event is! KeyDownEvent ||
                    !isEnter ||
                    HardwareKeyboard.instance.isShiftPressed) {
                  return KeyEventResult.ignored;
                }
                if (_canSend) onSend();
                return KeyEventResult.handled;
              },
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) {
                  if (_canSend) onSend();
                  focusNode.requestFocus();
                },
                decoration: InputDecoration(
                  hintText: hint,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: BorderSide(color: scheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: BorderSide(color: scheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: BorderSide(color: scheme.primary, width: 2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Enviar',
            iconSize: 22,
            style: IconButton.styleFrom(minimumSize: const Size(52, 52)),
            onPressed: _canSend ? onSend : null,
            icon: const Icon(Icons.arrow_upward_rounded),
          ),
        ],
      ),
    );
  }
}
