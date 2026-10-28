import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:avataria/gemini_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  final Uint8List avatarImage;
  final Map<String, dynamic> profileData;

  ChatScreen({
    required this.avatarImage,
    required this.profileData,
    Key? key,
  }) : super(key: key) {
    if (profileData['nome'] == null) throw ArgumentError('Nome é obrigatório');
    if (profileData['personalidade'] == null)
      throw ArgumentError('Personalidade é obrigatória');
  }

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  late List<ChatMessage> _messages = [];
  late GeminiService _geminiService;
  late String _avatarId;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _avatarId = widget.profileData['id'];
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = prefs.getString('chat_$_avatarId');

    if (messagesJson != null && mounted) {
      setState(() {
        _messages = (jsonDecode(messagesJson) as List)
            .map((e) => ChatMessage.fromJson(e))
            .toList()
            .reversed
            .toList();
      });
    }
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'chat_$_avatarId',
      jsonEncode(_messages.reversed.map((e) => e.toJson()).toList()),
    );
  }

  void _initializeServices() async {
    final geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    _geminiService = GeminiService(apiKey: geminiApiKey);
  }

  void _addMessage(String text, {required bool isUser}) {
    if (!mounted) return;
    setState(() {
      _messages.insert(
          0,
          ChatMessage(
            text: text,
            isUser: isUser,
            timestamp: DateTime.now(),
          ));
    });
    _saveMessages();
  }

  List<Map<String, dynamic>> _formatarHistorico() {
    return _messages.reversed
        .map((msg) => {
              'autor': msg.isUser ? 'Usuário' : widget.profileData['nome'],
              'texto': msg.text,
            })
        .toList();
  }

  Future<void> _sendMessage() async {
    if (!mounted || _messageController.text.isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();
    _addMessage(message, isUser: true);

    try {
      final response = await _geminiService.createChatProfile(
        nome: widget.profileData['nome'],
        personalidade: widget.profileData['personalidade'],
        historico: _formatarHistorico(),
      );
      _addMessage(response, isUser: false);
    } catch (e) {
      _addMessage('Erro ao gerar resposta. Tente novamente.', isUser: false);
      debugPrint('Erro no Gemini: $e');
    }
  }

  Future<void> _clearChat() async {
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar histórico?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Apagar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _messages.clear());
      await _saveMessages();
    }
  }

  Future<void> _deleteMessage(int index) async {
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar mensagem?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Apagar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _messages.removeAt(index));
      await _saveMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: MemoryImage(widget.avatarImage),
              radius: 20,
            ),
            const SizedBox(width: 12),
            Text(widget.profileData['nome']),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      '${widget.profileData['nome']} está online...',
                      style: const TextStyle(color: Colors.grey, fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) => GestureDetector(
                      onLongPress: () => _deleteMessage(index),
                      child: ChatBubble(
                        message: _messages[index].text,
                        isUser: _messages[index].isUser,
                        timestamp: _messages[index].timestamp,
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Digite uma mensagem...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        text: json['text'],
        isUser: json['isUser'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final DateTime timestamp;

  const ChatBubble({
    required this.message,
    required this.isUser,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? Colors.blue.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUser ? Colors.blue : Colors.grey,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            Text(
              '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
