import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'ai_services.dart';
import 'prompts.dart';

/// [CaricatureGenerator] com a Images API da OpenAI.
///
/// Os modelos GPT Image sempre devolvem base64 em `data[0].b64_json`; o
/// parâmetro `response_format` da v1 (DALL·E) não existe mais para eles.
class OpenAiCaricatureGenerator implements CaricatureGenerator {
  OpenAiCaricatureGenerator({
    required this.apiKey,
    required this.model,
    http.Client? httpClient,
    this.size = '1024x1024',
    this.timeout = const Duration(minutes: 3),
  }) : _http = httpClient ?? http.Client();

  static final _endpoint = Uri.parse(
    'https://api.openai.com/v1/images/generations',
  );

  final String apiKey;
  final String model;
  final String size;
  final Duration timeout;
  final http.Client _http;

  @override
  Future<Uint8List> generate(String faceDescription) async {
    if (apiKey.isEmpty) {
      throw const AiException(
        'Chave da OpenAI não configurada. Rode o app com '
        '--dart-define-from-file=env.json (veja o README).',
      );
    }

    final http.Response response;
    try {
      response = await _http
          .post(
            _endpoint,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': model,
              'prompt': Prompts.caricature(faceDescription),
              'n': 1,
              'size': size,
            }),
          )
          .timeout(timeout);
    } on TimeoutException catch (e) {
      throw AiException('A geração da imagem demorou demais.', cause: e);
    } on http.ClientException catch (e) {
      throw AiException(
        'Sem conexão com a OpenAI. Verifique a internet.',
        cause: e,
      );
    }

    if (response.statusCode != 200) {
      throw AiException(
        _errorMessage(response.statusCode, response.body),
        cause: response.body,
      );
    }
    return parseImage(response.body);
  }

  static Uint8List parseImage(String body) {
    try {
      final json = jsonDecode(body) as Map<String, Object?>;
      final data = json['data']! as List<Object?>;
      final first = data.first! as Map<String, Object?>;
      return base64Decode(first['b64_json']! as String);
    } on Object catch (e) {
      throw AiException('Resposta inválida da OpenAI.', cause: e);
    }
  }

  static String _errorMessage(int status, String body) {
    if (body.contains('moderation_blocked') ||
        body.contains('content_policy')) {
      return 'A OpenAI recusou gerar essa imagem. Tente outra foto.';
    }
    return switch (status) {
      400 => 'A OpenAI rejeitou o pedido. Confira OPENAI_IMAGE_MODEL.',
      401 => 'Chave da OpenAI inválida.',
      403 => 'Sua conta OpenAI não tem acesso a esse modelo de imagem.',
      404 => 'Modelo de imagem não encontrado. Confira OPENAI_IMAGE_MODEL.',
      429 => 'Limite ou créditos da OpenAI esgotados. Tente mais tarde.',
      >= 500 => 'A OpenAI está instável agora. Tente de novo em instantes.',
      _ => 'Erro inesperado da OpenAI (HTTP $status).',
    };
  }
}
