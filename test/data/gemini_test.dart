import 'dart:convert';
import 'dart:typed_data';

import 'package:avataria/data/ai/ai_services.dart';
import 'package:avataria/data/ai/gemini.dart';
import 'package:avataria/data/models/avatar.dart';
import 'package:avataria/data/models/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String _reply(String text) => jsonEncode({
  'candidates': [
    {
      'content': {
        'role': 'model',
        'parts': [
          {'text': text},
        ],
      },
      'finishReason': 'STOP',
    },
  ],
});

ChatMessage _msg(String text, {required bool user}) =>
    ChatMessage(text: text, fromUser: user, sentAt: DateTime(2026));

final _avatar = Avatar(
  id: 'a1',
  name: 'Zé',
  personality: 'piadista',
  createdAt: DateTime(2026),
);

void main() {
  group('GeminiClient', () {
    test('manda a chave no header, nunca na URL', () async {
      late http.Request sent;
      final client = GeminiClient(
        apiKey: 'chave-secreta',
        model: 'gemini-teste',
        httpClient: MockClient((request) async {
          sent = request;
          return http.Response(_reply('oi'), 200);
        }),
      );

      expect(await client.generate(contents: const []), 'oi');
      expect(sent.url.path, endsWith('/models/gemini-teste:generateContent'));
      expect(sent.url.query, isEmpty);
      expect(sent.headers['x-goog-api-key'], 'chave-secreta');
    });

    test('ignora partes de raciocínio e junta o texto', () {
      final body = jsonEncode({
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': 'pensando...', 'thought': true},
                {'text': 'Olá, '},
                {'text': 'tudo bem?'},
              ],
            },
          },
        ],
      });
      expect(GeminiClient.parseText(body), 'Olá, tudo bem?');
    });

    test('explica quando o conteúdo é bloqueado', () {
      final body = jsonEncode({
        'promptFeedback': {'blockReason': 'SAFETY'},
      });
      expect(
        () => GeminiClient.parseText(body),
        throwsA(
          isA<AiException>().having(
            (e) => e.message,
            'message',
            contains('recusou'),
          ),
        ),
      );
    });

    test('traduz erros HTTP em mensagens acionáveis', () async {
      Future<String> failWith(int status) => GeminiClient(
        apiKey: 'k',
        model: 'm',
        httpClient: MockClient((_) async => http.Response('{}', status)),
      ).generate(contents: const []);

      await expectLater(
        failWith(429),
        throwsA(
          isA<AiException>().having(
            (e) => e.message,
            'message',
            contains('Limite'),
          ),
        ),
      );
      await expectLater(
        failWith(404),
        throwsA(
          isA<AiException>().having(
            (e) => e.message,
            'message',
            contains('GEMINI_MODEL'),
          ),
        ),
      );
    });

    test('sem chave configurada, falha antes de chamar a rede', () async {
      var called = false;
      final client = GeminiClient(
        apiKey: '',
        model: 'm',
        httpClient: MockClient((_) async {
          called = true;
          return http.Response('', 200);
        }),
      );
      await expectLater(
        client.generate(contents: const []),
        throwsA(isA<AiException>()),
      );
      expect(called, isFalse);
    });
  });

  group('GeminiFaceDescriber', () {
    test('envia a foto em base64 com o mime type', () async {
      late Map<String, Object?> body;
      final describer = GeminiFaceDescriber(
        GeminiClient(
          apiKey: 'k',
          model: 'm',
          httpClient: MockClient((request) async {
            body = jsonDecode(request.body) as Map<String, Object?>;
            return http.Response(_reply('rosto oval'), 200);
          }),
        ),
      );

      final result = await describer.describe(
        Uint8List.fromList([1, 2, 3]),
        mimeType: 'image/png',
      );

      expect(result, 'rosto oval');
      final encoded = jsonEncode(body);
      expect(encoded, contains('"mime_type":"image/png"'));
      expect(encoded, contains('"data":"${base64Encode([1, 2, 3])}"'));
    });

    test('avisa quando não há rosto na foto', () async {
      final describer = GeminiFaceDescriber(
        GeminiClient(
          apiKey: 'k',
          model: 'm',
          httpClient: MockClient(
            (_) async => http.Response(_reply('SEM_ROSTO'), 200),
          ),
        ),
      );
      await expectLater(
        describer.describe(Uint8List(0)),
        throwsA(
          isA<AiException>().having(
            (e) => e.message,
            'message',
            contains('rosto'),
          ),
        ),
      );
    });
  });

  group('GeminiCharacterChat', () {
    test('usa systemInstruction e os papéis user/model', () async {
      late Map<String, Object?> body;
      final chat = GeminiCharacterChat(
        GeminiClient(
          apiKey: 'k',
          model: 'm',
          httpClient: MockClient((request) async {
            body = jsonDecode(request.body) as Map<String, Object?>;
            return http.Response(_reply('Fala!'), 200);
          }),
        ),
      );

      final reply = await chat.reply(
        avatar: _avatar,
        history: [
          _msg('oi', user: true),
          _msg('opa', user: false),
          _msg('tudo?', user: true),
        ],
      );

      expect(reply, 'Fala!');
      expect(jsonEncode(body['systemInstruction']), contains('Zé'));
      final roles = (body['contents']! as List<Object?>)
          .map((c) => (c! as Map<String, Object?>)['role'])
          .toList();
      expect(roles, ['user', 'model', 'user']);
    });

    test('limita o histórico e sempre começa com um turno do usuário', () {
      final history = [
        _msg('u1', user: true),
        _msg('m1', user: false),
        _msg('u2', user: true),
        _msg('m2', user: false),
        _msg('u3', user: true),
      ];
      final contents = GeminiCharacterChat.buildContents(
        history,
        maxHistory: 4,
      );
      final texts = contents
          .map(
            (c) =>
                ((c['parts']! as List<Object?>).first!
                    as Map<String, Object?>)['text'],
          )
          .toList();
      // O corte em 4 começaria em "m1"; essa fala do personagem é descartada.
      expect(texts, ['u2', 'm2', 'u3']);
    });
  });
}
