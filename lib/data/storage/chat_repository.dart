import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_message.dart';

/// Histórico de conversa de cada avatar, separado por usuário.
class ChatRepository {
  ChatRepository(this._prefs);

  final SharedPreferences _prefs;

  static String keyFor(String userId, String avatarId) =>
      'chat:$userId:$avatarId';

  /// Mensagens em ordem cronológica.
  List<ChatMessage> load(String userId, String avatarId) {
    final raw = _prefs.getString(keyFor(userId, avatarId));
    if (raw == null) return [];
    return (jsonDecode(raw) as List<Object?>)
        .cast<Map<String, Object?>>()
        .map(ChatMessage.fromJson)
        .toList();
  }

  Future<void> save(
    String userId,
    String avatarId,
    List<ChatMessage> messages,
  ) {
    return _prefs.setString(
      keyFor(userId, avatarId),
      jsonEncode([for (final m in messages) m.toJson()]),
    );
  }

  Future<void> clear(String userId, String avatarId) =>
      _prefs.remove(keyFor(userId, avatarId));
}
