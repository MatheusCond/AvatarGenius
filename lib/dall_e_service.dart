import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class DallEService {
  final String _apiKey;
  final String _baseUrl = 'https://api.openai.com/v1/images/generations';

  DallEService({required String apiKey}) : _apiKey = apiKey;

  Future<Uint8List> generateAvatar(String description) async {
    try {
      final String prompt =
          "Retrato digital em estilo cartoon de um único personagem caricato, com foco exclusivo em sua cabeça e ombros, perfeitamente centralizado na imagem. O avatar possui as seguintes características: $description. O fundo é suave e uniforme, sem elementos adicionais, para destacar somente este personagem.";

      final Map<String, dynamic> payload = {
        "model": "dall-e-3",
        "prompt": prompt,
        "n": 1,
        "size": "1024x1024",
        "response_format": "b64_json"
      };

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String base64Image = data['data'][0]['b64_json'];
        return base64Decode(base64Image);
      } else {
        if (kDebugMode) {
          print('Erro na API do DALL-E: ${response.body}');
        }
        throw Exception('Falha ao gerar avatar: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao gerar avatar: $e');
    }
  }
}
