import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GeminiService {
  final String _apiKey;
  final String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  GeminiService({required String apiKey}) : _apiKey = apiKey;

  Future<String> generateImageDescription(Uint8List imageBytes) async {
    try {
      final String base64Image = base64Encode(imageBytes);

      final Map<String, dynamic> payload = {
        "contents": [
          {
            "parts": [
              {
                "text":
                    "Gere uma descrição detalhada desta pessoa. Inclua: idade aproximada, formato do rosto, cor dos cabelos, expressões faciais, acessórios, etc. A descrição será usada para gerar um avatar caricato, então destaque características marcantes que poderiam ser exageradas em uma caricatura."
              },
              {
                "inline_data": {"mime_type": "image/jpeg", "data": base64Image}
              }
            ]
          }
        ],
        "generationConfig": {"temperature": 0.4, "maxOutputTokens": 300}
      };

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String description =
            data['candidates'][0]['content']['parts'][0]['text'];
        return description;
      } else {
        if (kDebugMode) {
          print('Erro na API do Gemini: ${response.body}');
        }
        throw Exception('Falha ao gerar descrição: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao processar imagem: $e');
    }
  }
}
