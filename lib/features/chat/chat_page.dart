import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../../app_services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/sticker.dart';
import '../../data/ai/ai_services.dart';
import '../../data/auth/auth_service.dart';
import '../../data/models/avatar.dart';
import '../../data/models/chat_message.dart';
import 'chat_widgets.dart';

/// Conversa com o avatar, no papel da personalidade escolhida.
class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.user,
    required this.avatar,
    required this.image,
  });

  final AppUser user;
  final Avatar avatar;
  final Uint8List image;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _input = TextEditingController();
  final _inputFocus = FocusNode();
  List<ChatMessage> _messages = const [];
  bool _waiting = false;
  bool _loaded = false;

  AppServices get _services => AppScope.of(context);

  static const _starters = [
    'Oi! Quem é você?',
    'Me conta uma piada',
    'O que você faz da vida?',
  ];

  @override
  void initState() {
    super.initState();
    _input.addListener(_onInputChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _messages = _services.chats.load(widget.user.id, widget.avatar.id);
      _loaded = true;
    }
  }

  @override
  void dispose() {
    _input
      ..removeListener(_onInputChanged)
      ..dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _onInputChanged() => setState(() {});

  Future<void> _persist() =>
      _services.chats.save(widget.user.id, widget.avatar.id, _messages);

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _waiting) return;
    _input.clear();

    setState(() {
      _messages = [
        ..._messages,
        ChatMessage(text: text, fromUser: true, sentAt: DateTime.now()),
      ];
      _waiting = true;
    });
    await _persist();
    await _requestReply();
  }

  Future<void> _requestReply() async {
    if (!_waiting) setState(() => _waiting = true);
    try {
      final reply = await _services.characterChat.reply(
        avatar: widget.avatar,
        history: _messages,
      );
      if (!mounted) return;
      setState(() {
        _messages = [
          ..._messages,
          ChatMessage(text: reply, fromUser: false, sentAt: DateTime.now()),
        ];
      });
      await _persist();
    } on AiException catch (e) {
      // O erro não entra no histórico: na v1 ele era salvo como se fosse
      // uma fala do personagem.
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(e.message),
            duration: const Duration(seconds: 8),
            // Fica acima do campo de mensagem em vez de cobri-lo.
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
            action: SnackBarAction(
              label: 'Tentar de novo',
              onPressed: _requestReply,
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _waiting = false);
    }
  }

  Future<bool> _confirm(String title, String action) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _clear() async {
    if (_messages.isEmpty) return;
    final confirmed = await _confirm(
      'Apagar a conversa com ${widget.avatar.name}?',
      'Apagar',
    );
    if (!confirmed) return;
    setState(() => _messages = const []);
    await _services.chats.clear(widget.user.id, widget.avatar.id);
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    if (!await _confirm('Apagar esta mensagem?', 'Apagar')) return;
    setState(() => _messages = _messages.where((m) => m != message).toList());
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    final avatar = widget.avatar;
    final brand = BrandColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    // A lista é invertida para abrir já na mensagem mais recente.
    final items = _messages.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Sticker(
              size: 42,
              child: Image.memory(widget.image, fit: BoxFit.cover),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    avatar.name,
                    style: textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _waiting ? 'digitando…' : avatar.personality,
                    style: textTheme.bodySmall?.copyWith(color: brand.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<void>(
            tooltip: 'Mais opções',
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: _clear,
                enabled: _messages.isNotEmpty,
                child: const Text('Apagar conversa'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_services.config.demoMode)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: DemoBanner(
                  message: 'Modo demo: as respostas são simuladas, sem IA.',
                ),
              ),
            Expanded(
              child: items.isEmpty && !_waiting
                  ? _EmptyChat(
                      avatar: avatar,
                      image: widget.image,
                      starters: _starters,
                      onStarter: _send,
                    )
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount: items.length + (_waiting ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_waiting && index == 0) {
                          return TypingBubble(name: avatar.name);
                        }
                        final message = items[index - (_waiting ? 1 : 0)];
                        return MessageBubble(
                          message: message,
                          onLongPress: () => _deleteMessage(message),
                        );
                      },
                    ),
            ),
            Composer(
              controller: _input,
              focusNode: _inputFocus,
              hint: 'Mensagem para ${avatar.name}',
              enabled: !_waiting,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({
    required this.avatar,
    required this.image,
    required this.starters,
    required this.onStarter,
  });

  final Avatar avatar;
  final Uint8List image;
  final List<String> starters;
  final ValueChanged<String> onStarter;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ContentWidth(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Sticker(
              size: 140,
              tiltDegrees: 2,
              child: Image.memory(image, fit: BoxFit.cover),
            ),
            const SizedBox(height: 24),
            Text(
              'Diga oi para ${avatar.name}',
              style: textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              avatar.personality,
              style: textTheme.bodyMedium?.copyWith(
                color: BrandColors.of(context).muted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final starter in starters)
                  ActionChip(
                    label: Text(starter),
                    onPressed: () => onStarter(starter),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
