import 'dart:typed_data';

import '../../core/art/caricature_face.dart';
import '../models/avatar.dart';
import '../models/chat_message.dart';
import 'ai_services.dart';

/// Implementações locais usadas no modo demo: funcionam sem chave de API,
/// sem custo e offline, para qualquer pessoa testar o fluxo completo.

class DemoFaceDescriber implements FaceDescriber {
  const DemoFaceDescriber({this.delay = const Duration(milliseconds: 1200)});

  final Duration delay;

  @override
  Future<String> describe(
    Uint8List photo, {
    String mimeType = 'image/jpeg',
  }) async {
    await Future<void>.delayed(delay);
    // A "descrição" carrega uma semente derivada da foto, para fotos
    // diferentes virarem caricaturas diferentes.
    return 'demo-seed:${_fingerprint(photo)}';
  }

  static int _fingerprint(Uint8List bytes) {
    var hash = 0x811c9dc5;
    final step = bytes.length < 4096 ? 1 : bytes.length ~/ 4096;
    for (var i = 0; i < bytes.length; i += step) {
      hash = ((hash ^ bytes[i]) * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}

class DemoCaricatureGenerator implements CaricatureGenerator {
  const DemoCaricatureGenerator({
    this.delay = const Duration(milliseconds: 1500),
  });

  final Duration delay;

  @override
  Future<Uint8List> generate(String faceDescription) async {
    await Future<void>.delayed(delay);
    final seed =
        int.tryParse(faceDescription.split(':').last) ??
        faceDescription.hashCode;
    return renderCaricaturePng(CaricatureTraits.fromSeed(seed));
  }
}

class DemoCharacterChat implements CharacterChat {
  const DemoCharacterChat({this.delay = const Duration(milliseconds: 900)});

  final Duration delay;

  static const _openers = ['Olha, ', 'Rapaz, ', 'Então, ', 'Bom, ', 'Hmm, '];

  @override
  Future<String> reply({
    required Avatar avatar,
    required List<ChatMessage> history,
  }) async {
    await Future<void>.delayed(delay);
    final last = history.lastWhere(
      (m) => m.fromUser,
      orElse: () =>
          ChatMessage(text: '', fromUser: true, sentAt: DateTime.now()),
    );
    final opener = _openers[history.length % _openers.length];
    final trait = avatar.personality
        .split(RegExp(r'[,.;]'))
        .first
        .trim()
        .toLowerCase();

    if (last.text.trim().endsWith('?')) {
      return '${opener}como alguém $trait, eu diria que depende! '
          'Me conta mais que eu te digo o que acho.';
    }
    return '${opener}gostei disso! Aqui é ${avatar.name}, e você já sabe: '
        '$trait até o fim.';
  }
}
