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
                    "Gere uma descrição detalhada desta pessoa. Inclua: Formato do rosto, Tom de pele, Textura da pele, Cor da pele, Estilo do cabelo, Comprimento do cabelo, Corte do cabelo, Cor do cabelo, Formato dos olhos, Cor da íris, Brilho nos olhos, Detalhes ao redor dos olhos, Espessura das sobrancelhas, Formato das sobrancelhas, Cor das sobrancelhas, Formato do nariz, Detalhes do nariz, Espessura dos lábios, Formato dos lábios, Textura dos lábios, Cor dos lábios, Tipo de barba, Bigode, Cor da barba e do bigode, Expressão facial, Óculos, Piercings, Brincos, Tatuagens, Chapéus e bonés, Tipo de roupa, Estampa ou cor da roupa, Ajuste da roupa. Não diga mais nada além da descrição"
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
