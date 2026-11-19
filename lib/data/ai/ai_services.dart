import 'dart:typed_data';

import '../models/avatar.dart';
import '../models/chat_message.dart';

/// Erro de IA com uma mensagem pronta para mostrar na tela.
class AiException implements Exception {
  const AiException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'AiException: $message${cause == null ? '' : ' ($cause)'}';
}

/// Passo 1 do pipeline: descreve em texto o rosto da foto.
abstract interface class FaceDescriber {
  Future<String> describe(Uint8List photo, {String mimeType = 'image/jpeg'});
}

/// Passo 2 do pipeline: desenha a caricatura a partir da descrição.
abstract interface class CaricatureGenerator {
  /// Retorna os bytes de uma imagem PNG.
  Future<Uint8List> generate(String faceDescription);
}

/// Conversa com o avatar no papel do personagem.
abstract interface class CharacterChat {
  /// [history] vem em ordem cronológica e já inclui a última mensagem do
  /// usuário.
  Future<String> reply({
    required Avatar avatar,
    required List<ChatMessage> history,
  });
}
