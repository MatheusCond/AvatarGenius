import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

void main() {
  testWidgets('valida os campos antes de tentar entrar', (tester) async {
    final harness = await TestHarness.create();
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Entrar'));

    expect(find.text('Informe seu email.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
  });

  testWidgets('entrar leva à galeria vazia e sair volta ao login', (
    tester,
  ) async {
    final harness = await TestHarness.create();
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'ana@exemplo.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Senha'),
      'segredo1',
    );
    await tapVisible(tester, find.text('Entrar'));

    expect(find.text('Nenhum avatar ainda'), findsOneWidget);

    await tapVisible(tester, find.byTooltip('Sair da conta'));

    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('cadastro com senhas diferentes mostra o erro', (tester) async {
    final harness = await TestHarness.create();
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Criar conta'));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'ana@exemplo.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Senha'),
      'segredo1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Repita a senha'),
      'outra123',
    );
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Criar conta'));

    expect(find.text('As senhas não são iguais.'), findsOneWidget);
  });
}
