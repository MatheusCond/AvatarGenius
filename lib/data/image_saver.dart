import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';

class ImageSaveException implements Exception {
  const ImageSaveException(this.message);

  final String message;

  @override
  String toString() => 'ImageSaveException: $message';
}

/// Salva imagens na galeria do aparelho.
abstract interface class ImageSaver {
  bool get isSupported;

  Future<void> save(Uint8List png, {required String name});
}

/// Usa o pacote `gal`, que já trata as permissões de cada versão do
/// Android. Substitui o `image_gallery_saver` da v1, que estava abandonado
/// e exigia um patch local no Gradle.
class GalImageSaver implements ImageSaver {
  const GalImageSaver();

  @override
  bool get isSupported => !kIsWeb;

  @override
  Future<void> save(Uint8List png, {required String name}) async {
    try {
      if (!await Gal.hasPermission() && !await Gal.requestPermission()) {
        throw const ImageSaveException(
          'Sem permissão para salvar fotos. Libere o acesso nas configurações do app.',
        );
      }
      await Gal.putImageBytes(png, name: name);
    } on GalException catch (e) {
      throw ImageSaveException(switch (e.type) {
        GalExceptionType.permissionDenied =>
          'Sem permissão para salvar fotos. Libere o acesso nas configurações do app.',
        GalExceptionType.notEnoughSpace => 'Sem espaço no aparelho.',
        _ => 'Não foi possível salvar a imagem.',
      });
    }
  }
}
