import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'image_store.dart';

Future<ImageStore> createPlatformImageStore(SharedPreferences prefs) async {
  final support = await getApplicationSupportDirectory();
  return FileImageStore(Directory('${support.path}/avatars'));
}

/// Salva cada imagem como um arquivo PNG na pasta privada do app.
class FileImageStore implements ImageStore {
  FileImageStore(this.root);

  final Directory root;

  File _file(String key) {
    final safe = key.replaceAll(RegExp(r'[^A-Za-z0-9_\-/]'), '_');
    return File('${root.path}/$safe.png');
  }

  @override
  Future<void> write(String key, Uint8List bytes) async {
    final file = _file(key);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
  }

  @override
  Future<Uint8List?> read(String key) async {
    final file = _file(key);
    return await file.exists() ? file.readAsBytes() : null;
  }

  @override
  Future<void> delete(String key) async {
    final file = _file(key);
    if (await file.exists()) await file.delete();
  }
}
