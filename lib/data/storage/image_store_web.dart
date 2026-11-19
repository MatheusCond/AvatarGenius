import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import 'image_store.dart';

Future<ImageStore> createPlatformImageStore(SharedPreferences prefs) async =>
    PrefsImageStore(prefs);

/// Na web não há sistema de arquivos: as imagens vão em base64 no
/// `localStorage`. Serve para a demo; o limite do navegador (~5 MB) cabe
/// poucas imagens em alta resolução.
class PrefsImageStore implements ImageStore {
  PrefsImageStore(this._prefs);

  final SharedPreferences _prefs;

  String _key(String key) => 'image:$key';

  @override
  Future<void> write(String key, Uint8List bytes) =>
      _prefs.setString(_key(key), base64Encode(bytes));

  @override
  Future<Uint8List?> read(String key) async {
    final data = _prefs.getString(_key(key));
    return data == null ? null : base64Decode(data);
  }

  @override
  Future<void> delete(String key) => _prefs.remove(_key(key));
}
