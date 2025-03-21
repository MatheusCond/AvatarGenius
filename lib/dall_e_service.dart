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
          "Crie um único avatar caricato estilo cartoon com as seguintes características: $description. O avatar deve ser individual, sem variações ou versões alternativas. Mantenha um estilo colorido e divertido, com proporções exageradas para destacar as características únicas. Inclua todos os detalhes da face mencionados, como cabelo, barba e expressões faciais. A barba deve ser bem definida e estilizada. O fundo deve ser neutro ou branco, adequado para um avatar de perfil.";

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
