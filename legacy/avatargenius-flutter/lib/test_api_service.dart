// test_api_service.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

Future<bool> testOpenAIAuth() async {
  final apiKey = dotenv.env['OPENAI_API_KEY'];
  print('Testando chave: ${apiKey?.substring(0, 5)}...');
  
  try {
    final response = await http.get(
      Uri.parse('https://api.openai.com/v1/models'),
      headers: {
        'Authorization': 'Bearer $apiKey',
      },
    );
    
    print('Status code: ${response.statusCode}');
    print('Response body: ${response.body.substring(0, 100)}...');
    
    return response.statusCode == 200;
  } catch (e) {
    print('Erro no teste: $e');
    return false;
  }
}