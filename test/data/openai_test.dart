import 'dart:convert';

import 'package:avataria/data/ai/ai_services.dart';
import 'package:avataria/data/ai/openai_caricature_generator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('decodifica a imagem base64 e não envia response_format', () async {
    late http.Request sent;
    final generator = OpenAiCaricatureGenerator(
      apiKey: 'sk-teste',
      model: 'gpt-image-teste',
      httpClient: MockClient((request) async {
        sent = request;
        return http.Response(
          jsonEncode({
            'data': [
              {
                'b64_json': base64Encode([7, 8, 9]),
              },
            ],
          }),
          200,
        );
      }),
    );

    final bytes = await generator.generate('rosto oval');

    expect(bytes, [7, 8, 9]);
    expect(sent.headers['Authorization'], 'Bearer sk-teste');
    final body = jsonDecode(sent.body) as Map<String, Object?>;
    expect(body['model'], 'gpt-image-teste');
    expect(body['prompt'], contains('rosto oval'));
    expect(body.containsKey('response_format'), isFalse);
  });

  test('explica bloqueio de moderação', () async {
    final generator = OpenAiCaricatureGenerator(
      apiKey: 'k',
      model: 'm',
      httpClient: MockClient(
        (_) async =>
            http.Response('{"error":{"code":"moderation_blocked"}}', 400),
      ),
    );
    await expectLater(
      generator.generate('x'),
      throwsA(
        isA<AiException>().having(
          (e) => e.message,
          'message',
          contains('recusou'),
        ),
      ),
    );
  });

  test('explica créditos esgotados', () async {
    final generator = OpenAiCaricatureGenerator(
      apiKey: 'k',
      model: 'm',
      httpClient: MockClient((_) async => http.Response('{}', 429)),
    );
    await expectLater(
      generator.generate('x'),
      throwsA(
        isA<AiException>().having(
          (e) => e.message,
          'message',
          contains('créditos'),
        ),
      ),
    );
  });

  test('resposta sem imagem vira AiException', () {
    expect(
      () => OpenAiCaricatureGenerator.parseImage('{"data":[]}'),
      throwsA(isA<AiException>()),
    );
  });
}
