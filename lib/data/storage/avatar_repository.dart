import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/avatar.dart';
import '../models/chat_message.dart';
import 'chat_repository.dart';
import 'image_store.dart';

/// Avatares do usuário guardados no aparelho.
///
/// Os metadados ficam numa lista JSON por usuário no SharedPreferences e as
/// imagens num [ImageStore]. Na v1 tudo ia em base64 no SharedPreferences,
/// sem separar por usuário: quem entrasse com outra conta via os avatares
/// da anterior.
class AvatarRepository {
  AvatarRepository({
    required SharedPreferences prefs,
    required ImageStore images,
    required ChatRepository chats,
    DateTime Function()? clock,
    Random? random,
  }) : _prefs = prefs,
       _images = images,
       _chats = chats,
       _clock = clock ?? DateTime.now,
       _random = random ?? Random();

  final SharedPreferences _prefs;
  final ImageStore _images;
  final ChatRepository _chats;
  final DateTime Function() _clock;
  final Random _random;

  static String _listKey(String userId) => 'avatars:$userId';
  static String _imageKey(String userId, String avatarId) =>
      '$userId/$avatarId';

  /// Avatares do usuário, do mais novo para o mais antigo.
  Future<List<Avatar>> list(String userId) async {
    await _migrateLegacyData(userId);
    final avatars = _readList(userId)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return avatars;
  }

  Future<Uint8List?> loadImage(String userId, String avatarId) =>
      _images.read(_imageKey(userId, avatarId));

  Future<Avatar> create(
    String userId, {
    required Uint8List image,
    required String name,
    required String personality,
  }) async {
    final now = _clock();
    final avatar = Avatar(
      id: '${now.millisecondsSinceEpoch}-${_random.nextInt(1 << 20).toRadixString(36)}',
      name: name.trim(),
      personality: personality.trim(),
      createdAt: now,
    );
    // Imagem primeiro: se falhar, a lista não fica com um item sem imagem.
    await _images.write(_imageKey(userId, avatar.id), image);
    await _writeList(userId, [..._readList(userId), avatar]);
    return avatar;
  }

  /// Remove o avatar, a imagem e o histórico de conversa.
  Future<void> delete(String userId, String avatarId) async {
    await _writeList(
      userId,
      _readList(userId).where((a) => a.id != avatarId).toList(),
    );
    await _images.delete(_imageKey(userId, avatarId));
    await _chats.clear(userId, avatarId);
  }

  List<Avatar> _readList(String userId) {
    final raw = _prefs.getString(_listKey(userId));
    if (raw == null) return [];
    return (jsonDecode(raw) as List<Object?>)
        .cast<Map<String, Object?>>()
        .map(Avatar.fromJson)
        .toList();
  }

  Future<void> _writeList(String userId, List<Avatar> avatars) =>
      _prefs.setString(
        _listKey(userId),
        jsonEncode([for (final a in avatars) a.toJson()]),
      );

  /// Traz os avatares salvos pela v1 (`avatar_<timestamp>`,
  /// `avatar_<timestamp>_profile` e `chat_avatar_<timestamp>`) para a conta
  /// que entrar primeiro, e apaga as chaves antigas.
  Future<void> _migrateLegacyData(String userId) async {
    final legacyIds = _prefs
        .getKeys()
        .where((k) => RegExp(r'^avatar_\d+$').hasMatch(k))
        .toList();
    if (legacyIds.isEmpty) return;

    final migrated = _readList(userId);
    for (final legacyId in legacyIds) {
      final image = _prefs.getString(legacyId);
      final profile = _prefs.getString('${legacyId}_profile');
      if (image != null && profile != null) {
        try {
          final json = jsonDecode(profile) as Map<String, Object?>;
          final millis = int.parse(legacyId.substring('avatar_'.length));
          final avatar = Avatar(
            id: legacyId,
            name: (json['nome'] as String?) ?? 'Sem nome',
            personality: (json['personalidade'] as String?) ?? '',
            createdAt: DateTime.fromMillisecondsSinceEpoch(millis),
          );
          await _images.write(
            _imageKey(userId, avatar.id),
            base64Decode(image),
          );
          migrated.add(avatar);

          final chat = _prefs.getString('chat_$legacyId');
          if (chat != null) {
            final messages = (jsonDecode(chat) as List<Object?>)
                .cast<Map<String, Object?>>()
                .map(ChatMessage.fromJson)
                .toList();
            await _chats.save(userId, avatar.id, messages);
          }
        } on Object {
          // Dado antigo corrompido: descarta em vez de travar a galeria.
        }
      }
      await _prefs.remove(legacyId);
      await _prefs.remove('${legacyId}_profile');
      await _prefs.remove('chat_$legacyId');
    }
    await _writeList(userId, migrated);
  }
}
