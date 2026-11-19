import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_services.dart';
import 'config/app_config.dart';
import 'data/ai/demo_ai.dart';
import 'data/ai/gemini.dart';
import 'data/ai/openai_caricature_generator.dart';
import 'data/auth/demo_auth_service.dart';
import 'data/auth/firebase_auth_service.dart';
import 'data/image_saver.dart';
import 'data/storage/avatar_repository.dart';
import 'data/storage/chat_repository.dart';
import 'data/storage/image_store.dart';
import 'firebase_options.dart';

/// Monta as dependências do app conforme a [AppConfig].
Future<AppServices> bootstrap(AppConfig config) async {
  final prefs = await SharedPreferences.getInstance();
  final chats = ChatRepository(prefs);
  final avatars = AvatarRepository(
    prefs: prefs,
    images: await createImageStore(prefs),
    chats: chats,
  );

  if (config.demoMode) {
    return AppServices(
      config: config,
      auth: DemoAuthService(),
      faceDescriber: const DemoFaceDescriber(),
      caricatureGenerator: const DemoCaricatureGenerator(),
      characterChat: const DemoCharacterChat(),
      avatars: avatars,
      chats: chats,
      imageSaver: const GalImageSaver(),
    );
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final gemini = GeminiClient(
    apiKey: config.geminiApiKey,
    model: config.geminiModel,
  );

  return AppServices(
    config: config,
    auth: FirebaseAuthService(),
    faceDescriber: GeminiFaceDescriber(gemini),
    caricatureGenerator: OpenAiCaricatureGenerator(
      apiKey: config.openAiApiKey,
      model: config.imageModel,
    ),
    characterChat: GeminiCharacterChat(gemini),
    avatars: avatars,
    chats: chats,
    imageSaver: const GalImageSaver(),
  );
}
