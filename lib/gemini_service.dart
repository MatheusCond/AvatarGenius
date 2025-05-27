//lib/gemini_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GeminiService {
  final String _apiKey;
  final String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  GeminiService({required String apiKey}) : _apiKey = apiKey;

  Future<String> generateImageDescription(Uint8List imageBytes) async {
    final String base64Image = base64Encode(imageBytes);

    final String prompt = '''
Analise a foto e escreva um parágrafo descritivo, em linguagem clara e visual, contendo as seguintes informações sobre esta pessoa:
1. Formato do rosto (ex.: oval, quadrado)
2. Tom, cor e textura da pele (ex.: oliva, suave, com pequenas sardas)
3. Cabelo
  • Tipo e textura (ex.: liso tipo 1, ondulado tipo 2, cacheado tipo 3A/3B/3C, coily tipo 4A/4B/4C)
  • Padrão dos cachos (ex.: cachos em mola definidos, ondas largas soltas)
  • Volume e densidade (ex.: fino e ralo, grosso e volumoso)
  • Comprimento e corte (ex.: na altura dos ombros, em camadas)
  • Linha do cabelo e franja (ex.: risca lateral funda, testa livre)
  • Cor, reflexos e pontas (ex.: castanho médio com mechas loiras)
4. Formato dos olhos, cor da íris e brilho (ex.: amendoados, verde-água, brilho vivo) e detalhes ao redor (ex.: pés de galinha sutis)
5. Sobrancelhas (formato, espessura e cor)
6. Nariz (formato e detalhes, como ponte reta ou ponta arredondada)
7. Lábios (forma, espessura, textura e cor)
8. Barba e bigode, se presentes (tipo, comprimento e cor)
9. Expressão facial (ex.: sorriso leve, olhar pensativo)
10. Acessórios faciais (óculos, piercings, brincos ou tatuagens visíveis)
11. Chapéus ou bonés, se houver
12. Roupa (tipo de peça, cor ou estampa e caimento)
13. Gênero aparente (masculino, feminino ou outro)

Forneça apenas esse texto descritivo, escrevendo em um único parágrafo coeso.
''';

    final Map<String, dynamic> payload = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Image,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.9,
        'maxOutputTokens': 300,
      }
    };

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['candidates'][0]['content']['parts'][0]['text'] as String;
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

  Future<String> createChatProfile({
    required String nome,
    required String personalidade,
    required List<Map<String, dynamic>> historico,
  }) async {
    final prompt = '''
Você é o personagem "$nome", com a seguinte personalidade: 
"$personalidade"

Você deve responder sempre no papel deste personagem, usando tom e vocabulário coerentes com a personalidade fornecida. 
Matenha-se sempre no personagem ao longo da conversa!
Contexto da conversa atual:
${historico.map((msg) => "${msg['autor']}: ${msg['texto']}").join('\n')}

Sua resposta DEVE SER APENAS a continuação natural da conversa.
Não use cumprimentos em respostas subsequentes, use apenas se o usuário cumprimentar
''';

    final payload = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        }
      ],
      'generationConfig': {
        'temperature': 0.6, // Aumente para respostas mais criativas
        'maxOutputTokens': 300,
      },
    };

    final response = await http.post(
      Uri.parse('$_baseUrl?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'] as String;
    }
    throw Exception('Falha ao gerar resposta');
  }
}
