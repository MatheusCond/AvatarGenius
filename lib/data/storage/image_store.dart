import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import 'image_store_web.dart'
    if (dart.library.io) 'image_store_io.dart'
    as platform;

/// Guarda bytes de imagem por chave (ex.: `uid/avatarId`).
abstract interface class ImageStore {
  Future<void> write(String key, Uint8List bytes);

  Future<Uint8List?> read(String key);

  Future<void> delete(String key);
}

/// Escolhe o armazenamento da plataforma: arquivos no Android e
/// `localStorage` na web.
Future<ImageStore> createImageStore(SharedPreferences prefs) =>
    platform.createPlatformImageStore(prefs);

/// Armazenamento em memória, usado nos testes.
class MemoryImageStore implements ImageStore {
  final Map<String, Uint8List> files = {};

  @override
  Future<void> write(String key, Uint8List bytes) async => files[key] = bytes;

  @override
  Future<Uint8List?> read(String key) async => files[key];

  @override
  Future<void> delete(String key) async => files.remove(key);
}
