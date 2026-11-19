import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/avatar.dart';
import '../models/chat_message.dart';
import 'ai_services.dart';
import 'prompts.dart';

/// Cliente mínimo da API REST `generateContent` do Gemini.
///
/// A chave vai no header `x-goog-api-key`, e não na URL, para não aparecer
/// em logs de proxy ou de erro.
class GeminiClient {
  GeminiClient({
    required this.apiKey,
    required this.model,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 60),
  }) : _http = httpClient ?? http.Client();

  static const _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  final String apiKey;
  final String model;
  final Duration timeout;
  final http.Client _http;

  Future<String> generate({
    required List<Map<String, Object?>> contents,
    String? systemInstruction,
    double temperature = 0.7,
    int maxOutputTokens = 2048,
  }) async {
    if (apiKey.isEmpty) {
      throw const AiException(
        'Chave do Gemini não configurada. Rode o app com '
        '--dart-define-from-file=env.json (veja o README).',
      );
    }

    final http.Response response;
    try {
      response = await _http
          .post(
            Uri.parse('$_baseUrl/models/$model:generateContent'),
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': apiKey,
            },
            body: jsonEncode({
              if (systemInstruction != null)
                'systemInstruction': {
                  'parts': [
                    {'text': systemInstruction},
                  ],
                },
              'contents': contents,
              'generationConfig': {
                'temperature': temperature,
                'maxOutputTokens': maxOutputTokens,
              },
            }),
          )
          .timeout(timeout);
    } on TimeoutException catch (e) {
      throw AiException('O Gemini demorou demais para responder.', cause: e);
    } on http.ClientException catch (e) {
      throw AiException(
        'Sem conexão com o Gemini. Verifique a internet.',
        cause: e,
      );
    }

    if (response.statusCode != 200) {
      throw AiException(
        _httpErrorMessage(response.statusCode),
        cause: response.body,
      );
    }
    return parseText(response.body);
  }

  /// Extrai o texto da resposta, tratando bloqueios e respostas vazias.
  static String parseText(String body) {
    final Map<String, Object?> json;
    try {
      json = jsonDecode(body) as Map<String, Object?>;
    } on FormatException catch (e) {
      throw AiException('Resposta inválida do Gemini.', cause: e);
    }

    final candidates = json['candidates'] as List<Object?>? ?? const [];
    if (candidates.isEmpty) {
      final feedback = json['promptFeedback'] as Map<String, Object?>?;
      if (feedback?['blockReason'] != null) {
        throw const AiException(
          'O Gemini recusou este conteúdo. Tente outra foto ou outra mensagem.',
        );
      }
      throw const AiException('O Gemini não retornou resposta. Tente de novo.');
    }

    final candidate = candidates.first! as Map<String, Object?>;
    final content = candidate['content'] as Map<String, Object?>?;
    final parts = content?['parts'] as List<Object?>? ?? const [];
    final text = parts
        .cast<Map<String, Object?>>()
        .where((part) => part['thought'] != true)
        .map((part) => part['text'])
        .whereType<String>()
        .join()
        .trim();

    if (text.isEmpty) {
      final reason = candidate['finishReason'];
      if (reason == 'SAFETY' || reason == 'PROHIBITED_CONTENT') {
        throw const AiException(
          'O Gemini recusou este conteúdo. Tente outra foto ou outra mensagem.',
        );
      }
      throw const AiException('O Gemini não retornou resposta. Tente de novo.');
    }
    return text;
  }

  static String _httpErrorMessage(int status) {
    return switch (status) {
      400 => 'O Gemini rejeitou o pedido. Confira a chave GEMINI_API_KEY.',
      401 || 403 => 'Chave do Gemini inválida ou sem permissão.',
      404 => 'Modelo do Gemini não encontrado. Confira GEMINI_MODEL.',
      429 =>
        'Limite de uso do Gemini atingido. Espere um pouco e tente de novo.',
      >= 500 => 'O Gemini está instável agora. Tente de novo em instantes.',
      _ => 'Erro inesperado do Gemini (HTTP $status).',
    };
  }
}

/// [FaceDescriber] que manda a foto para o Gemini.
class GeminiFaceDescriber implements FaceDescriber {
  GeminiFaceDescriber(this._client);

  final GeminiClient _client;

  @override
  Future<String> describe(
    Uint8List photo, {
    String mimeType = 'image/jpeg',
  }) async {
    final description = await _client.generate(
      temperature: 0.4,
      contents: [
        {
          'role': 'user',
          'parts': [
            {'text': Prompts.faceDescription},
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Encode(photo),
              },
            },
          ],
        },
      ],
    );
    if (description.contains(Prompts.noFaceToken)) {
      throw const AiException(
        'Não encontramos um rosto nessa foto. Use uma foto de frente, '
        'com o rosto bem visível.',
      );
    }
    return description;
  }
}

/// [CharacterChat] com o Gemini, usando `systemInstruction` para o papel e
/// os turnos `user`/`model` para o histórico.
class GeminiCharacterChat implements CharacterChat {
  GeminiCharacterChat(this._client, {this.maxHistory = 30});

  final GeminiClient _client;

  /// Quantas mensagens recentes vão no contexto, para limitar custo e
  /// latência em conversas longas.
  final int maxHistory;

  @override
  Future<String> reply({
    required Avatar avatar,
    required List<ChatMessage> history,
  }) {
    return _client.generate(
      systemInstruction: Prompts.character(avatar),
      temperature: 0.8,
      contents: buildContents(history, maxHistory: maxHistory),
    );
  }

  /// Converte o histórico para o formato da API. O Gemini exige que a
  /// conversa comece com um turno `user`, então descartamos falas iniciais
  /// do personagem que sobrem após o corte.
  static List<Map<String, Object?>> buildContents(
    List<ChatMessage> history, {
    required int maxHistory,
  }) {
    var recent = history.length > maxHistory
        ? history.sublist(history.length - maxHistory)
        : history;
    final firstUser = recent.indexWhere((m) => m.fromUser);
    recent = firstUser == -1 ? const [] : recent.sublist(firstUser);

    return [
      for (final message in recent)
        {
          'role': message.fromUser ? 'user' : 'model',
          'parts': [
            {'text': message.text},
          ],
        },
    ];
  }
}
