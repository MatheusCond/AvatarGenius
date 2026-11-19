import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

/// Abre a imagem em tela cheia com zoom por pinça.
Future<void> showImageViewer(
  BuildContext context,
  Uint8List bytes, {
  required String semanticLabel,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          leading: const CloseButton(),
        ),
        body: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: Image.memory(bytes, semanticLabel: semanticLabel),
          ),
        ),
      ),
    ),
  );
}
