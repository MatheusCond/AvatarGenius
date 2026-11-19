import 'dart:typed_data';

import 'package:avataria/app.dart';
import 'package:avataria/app_services.dart';
import 'package:avataria/config/app_config.dart';
import 'package:avataria/data/ai/ai_services.dart';
import 'package:avataria/data/auth/auth_service.dart';
import 'package:avataria/data/auth/demo_auth_service.dart';
import 'package:avataria/data/image_saver.dart';
import 'package:avataria/data/models/avatar.dart';
import 'package:avataria/data/models/chat_message.dart';
import 'package:avataria/data/storage/avatar_repository.dart';
import 'package:avataria/data/storage/chat_repository.dart';
import 'package:avataria/data/storage/image_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// PNG 1x1 válido, para widgets que exibem imagens nos testes.
final tinyPng = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xCF, 0xC0, 0xF0,
  0x1F, 0x00, 0x05, 0x00, 0x01, 0xFF, 0x89, 0x99, 0x3D, 0x1D, 0x00, 0x00,
  0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

class FakeFaceDescriber implements FaceDescriber {
  @override
  Future<String> describe(
    Uint8List photo, {
    String mimeType = 'image/jpeg',
  }) async => 'rosto oval, cabelo cacheado';
}

class FakeCaricatureGenerator implements CaricatureGenerator {
  @override
  Future<Uint8List> generate(String faceDescription) async => tinyPng;
}

/// Responde com um texto fixo ou lança o erro configurado.
class FakeCharacterChat implements CharacterChat {
  String reply_ = 'Opa, tudo certo por aqui!';
  AiException? error;
  final calls = <List<ChatMessage>>[];

  @override
  Future<String> reply({
    required Avatar avatar,
    required List<ChatMessage> history,
  }) async {
    calls.add(List.of(history));
    if (error != null) throw error!;
    return reply_;
  }
}

class FakeImageSaver implements ImageSaver {
  @override
  bool get isSupported => true;

  @override
  Future<void> save(Uint8List png, {required String name}) async {}
}

class TestHarness {
  TestHarness._(this.services, this.prefs, this.images, this.chat);

  final AppServices services;
  final SharedPreferences prefs;
  final MemoryImageStore images;
  final FakeCharacterChat chat;

  AvatarGeniusApp get app => AvatarGeniusApp(services: services);

  static Future<TestHarness> create({
    AppUser? signedIn,
    Map<String, Object> prefsValues = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefsValues);
    final prefs = await SharedPreferences.getInstance();
    final images = MemoryImageStore();
    final chats = ChatRepository(prefs);
    final chat = FakeCharacterChat();
    final services = AppServices(
      config: const AppConfig(),
      auth: DemoAuthService(initialUser: signedIn),
      faceDescriber: FakeFaceDescriber(),
      caricatureGenerator: FakeCaricatureGenerator(),
      characterChat: chat,
      avatars: AvatarRepository(prefs: prefs, images: images, chats: chats),
      chats: chats,
      imageSaver: FakeImageSaver(),
    );
    return TestHarness._(services, prefs, images, chat);
  }
}

/// Rola até o widget antes de tocar, já que os formulários passam da tela.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
