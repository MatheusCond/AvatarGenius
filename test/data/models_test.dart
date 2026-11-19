import 'package:avataria/data/models/avatar.dart';
import 'package:avataria/data/models/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Avatar sobrevive à ida e volta em JSON', () {
    final avatar = Avatar(
      id: '1',
      name: 'Zé',
      personality: 'piadista',
      createdAt: DateTime(2026, 11, 19, 10, 30),
    );
    expect(Avatar.fromJson(avatar.toJson()), avatar);
  });

  test('ChatMessage sobrevive à ida e volta em JSON', () {
    final message = ChatMessage(
      text: 'oi',
      fromUser: false,
      sentAt: DateTime(2026),
    );
    expect(ChatMessage.fromJson(message.toJson()), message);
  });

  test('ChatMessage lê o formato da v1', () {
    final message = ChatMessage.fromJson(const {
      'text': 'oi',
      'isUser': true,
      'timestamp': '2025-05-27T17:10:00.000',
    });
    expect(message.fromUser, isTrue);
    expect(message.sentAt, DateTime(2025, 5, 27, 17, 10));
  });
}
