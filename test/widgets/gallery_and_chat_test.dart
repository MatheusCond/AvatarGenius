import 'package:avataria/data/ai/ai_services.dart';
import 'package:avataria/data/auth/auth_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

const _user = AppUser(id: 'u1', email: 'ana@exemplo.com');

Future<TestHarness> _withAvatar() async {
  final harness = await TestHarness.create(signedIn: _user);
  await harness.services.avatars.create(
    _user.id,
    image: tinyPng,
    name: 'Zé Caricato',
    personality: 'Piadista',
  );
  return harness;
}

Future<void> _openChat(WidgetTester tester) async {
  await tapVisible(tester, find.text('Zé Caricato'));
  await tapVisible(tester, find.text('Conversar com Zé Caricato'));
}

void main() {
  testWidgets('galeria mostra os avatares do usuário', (tester) async {
    final harness = await _withAvatar();
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(find.text('Seus avatares'), findsOneWidget);
    expect(find.text('Zé Caricato'), findsOneWidget);
    expect(find.text('Novo avatar'), findsOneWidget);
  });

  testWidgets('excluir pede confirmação e remove da galeria', (tester) async {
    final harness = await _withAvatar();
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Zé Caricato'));
    await tapVisible(tester, find.text('Excluir avatar'));
    await tapVisible(tester, find.widgetWithText(TextButton, 'Excluir'));

    expect(find.text('Nenhum avatar ainda'), findsOneWidget);
    expect(await harness.services.avatars.list(_user.id), isEmpty);
  });

  testWidgets('chat envia a mensagem, mostra a resposta e salva o histórico', (
    tester,
  ) async {
    final harness = await _withAvatar();
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();
    await _openChat(tester);

    await tester.enterText(find.byType(TextField), 'Oi, tudo bem?');
    await tapVisible(tester, find.byTooltip('Enviar'));

    expect(find.text('Oi, tudo bem?'), findsOneWidget);
    expect(find.text('Opa, tudo certo por aqui!'), findsOneWidget);
    expect(harness.chat.calls.single.last.text, 'Oi, tudo bem?');

    final avatar = (await harness.services.avatars.list(_user.id)).single;
    expect(harness.services.chats.load(_user.id, avatar.id), hasLength(2));
  });

  testWidgets('erro da IA aparece como aviso e não entra no histórico', (
    tester,
  ) async {
    final harness = await _withAvatar();
    harness.chat.error = const AiException('Limite de uso do Gemini atingido.');
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();
    await _openChat(tester);

    await tester.enterText(find.byType(TextField), 'Alô?');
    await tapVisible(tester, find.byTooltip('Enviar'));

    expect(find.text('Limite de uso do Gemini atingido.'), findsOneWidget);
    expect(find.text('Tentar de novo'), findsOneWidget);

    final avatar = (await harness.services.avatars.list(_user.id)).single;
    final saved = harness.services.chats.load(_user.id, avatar.id);
    expect(saved.map((m) => m.text), ['Alô?']);
  });

  testWidgets('não envia mensagem só com espaços', (tester) async {
    final harness = await _withAvatar();
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();
    await _openChat(tester);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();

    final send = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.arrow_upward_rounded),
    );
    expect(send.onPressed, isNull);
  });

  testWidgets('Enter logo após digitar envia a mensagem', (tester) async {
    final harness = await _withAvatar();
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();
    await _openChat(tester);

    await tester.showKeyboard(find.byType(TextField));
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(text: 'Rápido!'),
    );
    // Sem pump: o Enter chega antes do próximo build.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(harness.chat.calls.single.last.text, 'Rápido!');
  });
}
