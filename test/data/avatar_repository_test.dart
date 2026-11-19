import 'dart:convert';
import 'dart:typed_data';

import 'package:avataria/data/models/chat_message.dart';
import 'package:avataria/data/storage/avatar_repository.dart';
import 'package:avataria/data/storage/chat_repository.dart';
import 'package:avataria/data/storage/image_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late MemoryImageStore images;
  late ChatRepository chats;
  late AvatarRepository repo;

  Future<void> setUpWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    prefs = await SharedPreferences.getInstance();
    images = MemoryImageStore();
    chats = ChatRepository(prefs);
    var tick = 0;
    repo = AvatarRepository(
      prefs: prefs,
      images: images,
      chats: chats,
      clock: () => DateTime(2026, 1, 1).add(Duration(minutes: tick++)),
    );
  }

  setUp(() => setUpWith({}));

  test('lista do mais novo para o mais antigo', () async {
    await repo.create(
      'u1',
      image: Uint8List(1),
      name: 'Primeiro',
      personality: 'calmo',
    );
    await repo.create(
      'u1',
      image: Uint8List(1),
      name: 'Segundo',
      personality: 'agitado',
    );

    final names = (await repo.list('u1')).map((a) => a.name);
    expect(names, ['Segundo', 'Primeiro']);
  });

  test('cada usuário só vê os próprios avatares', () async {
    await repo.create(
      'ana',
      image: Uint8List(1),
      name: 'Da Ana',
      personality: 'x',
    );
    await repo.create(
      'bia',
      image: Uint8List(1),
      name: 'Da Bia',
      personality: 'y',
    );

    expect((await repo.list('ana')).map((a) => a.name), ['Da Ana']);
    expect((await repo.list('bia')).map((a) => a.name), ['Da Bia']);
  });

  test('salva e recupera a imagem', () async {
    final avatar = await repo.create(
      'u1',
      image: Uint8List.fromList([1, 2, 3]),
      name: ' Zé ',
      personality: ' piadista ',
    );
    expect(avatar.name, 'Zé');
    expect(await repo.loadImage('u1', avatar.id), [1, 2, 3]);
  });

  test('excluir apaga imagem e conversa junto', () async {
    final avatar = await repo.create(
      'u1',
      image: Uint8List(1),
      name: 'Zé',
      personality: 'x',
    );
    await chats.save('u1', avatar.id, [
      ChatMessage(text: 'oi', fromUser: true, sentAt: DateTime(2026)),
    ]);

    await repo.delete('u1', avatar.id);

    expect(await repo.list('u1'), isEmpty);
    expect(images.files, isEmpty);
    expect(chats.load('u1', avatar.id), isEmpty);
  });

  test('migra os dados salvos pela v1 para a conta atual', () async {
    await setUpWith({
      'avatar_1717430400000': base64Encode([9, 9]),
      'avatar_1717430400000_profile': jsonEncode({
        'id': 'avatar_1717430400000',
        'nome': 'Antigo',
        'personalidade': 'nostálgico',
      }),
      'chat_avatar_1717430400000': jsonEncode([
        {'text': 'oi', 'isUser': true, 'timestamp': '2024-06-03T12:00:00.000'},
      ]),
    });

    final avatars = await repo.list('u1');

    expect(avatars.single.name, 'Antigo');
    expect(avatars.single.personality, 'nostálgico');
    expect(await repo.loadImage('u1', avatars.single.id), [9, 9]);
    expect(chats.load('u1', avatars.single.id).single.text, 'oi');
    expect(prefs.getKeys().where((k) => k.startsWith('avatar_')), isEmpty);
    // Outra conta não herda nada.
    expect(await repo.list('u2'), isEmpty);
  });
}
