import 'package:flutter/widgets.dart';

import 'config/app_config.dart';
import 'data/ai/ai_services.dart';
import 'data/auth/auth_service.dart';
import 'data/image_saver.dart';
import 'data/storage/avatar_repository.dart';
import 'data/storage/chat_repository.dart';

/// Todas as dependências do app, montadas uma vez em `bootstrap()`.
///
/// As telas dependem só das interfaces, o que permite trocar Firebase e IA
/// pelas versões demo ou por dublês nos testes.
class AppServices {
  const AppServices({
    required this.config,
    required this.auth,
    required this.faceDescriber,
    required this.caricatureGenerator,
    required this.characterChat,
    required this.avatars,
    required this.chats,
    required this.imageSaver,
  });

  final AppConfig config;
  final AuthService auth;
  final FaceDescriber faceDescriber;
  final CaricatureGenerator caricatureGenerator;
  final CharacterChat characterChat;
  final AvatarRepository avatars;
  final ChatRepository chats;
  final ImageSaver imageSaver;
}

/// Disponibiliza [AppServices] para a árvore de widgets.
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});

  final AppServices services;

  static AppServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope não encontrado na árvore de widgets.');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => oldWidget.services != services;
}
