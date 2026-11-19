import 'package:avataria/data/auth/auth_service.dart';
import 'package:avataria/data/auth/demo_auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('authErrorMessage', () {
    test('não revela se o email existe ao errar o login', () {
      const generic = 'Email ou senha incorretos.';
      expect(authErrorMessage('invalid-credential'), generic);
      expect(authErrorMessage('user-not-found'), generic);
      expect(authErrorMessage('wrong-password'), generic);
    });

    test('traduz os erros comuns de cadastro e rede', () {
      expect(
        authErrorMessage('email-already-in-use'),
        contains('Já existe uma conta'),
      );
      expect(
        authErrorMessage('too-many-requests'),
        contains('Muitas tentativas'),
      );
      expect(
        authErrorMessage('network-request-failed'),
        contains('Sem conexão'),
      );
    });

    test('tem uma mensagem genérica para códigos desconhecidos', () {
      expect(authErrorMessage('algo-novo'), contains('Tente de novo'));
    });
  });

  group('Credentials', () {
    test('valida email', () {
      expect(Credentials.validateEmail(''), isNotNull);
      expect(Credentials.validateEmail('sem-arroba'), isNotNull);
      expect(Credentials.validateEmail(' ana@exemplo.com '), isNull);
    });

    test('exige senha com 6 ou mais caracteres', () {
      expect(Credentials.validatePassword(''), isNotNull);
      expect(Credentials.validatePassword('12345'), isNotNull);
      expect(Credentials.validatePassword('123456'), isNull);
    });
  });

  group('DemoAuthService', () {
    test('emite o usuário atual e as mudanças de login', () async {
      final auth = DemoAuthService();
      final states = <AppUser?>[];
      final sub = auth.authStateChanges().listen(states.add);

      await auth.signIn(email: 'ana@exemplo.com', password: 'segredo1');
      await auth.signOut();
      await Future<void>.delayed(Duration.zero);

      expect(states.map((u) => u?.email), [null, 'ana@exemplo.com', null]);
      await sub.cancel();
    });

    test(
      'gera o mesmo id para o mesmo email, ignorando caixa e espaços',
      () async {
        final auth = DemoAuthService();
        await auth.signIn(email: 'Ana@Exemplo.com ', password: 'segredo1');
        final first = auth.currentUser!.id;
        await auth.signIn(email: 'ana@exemplo.com', password: 'segredo1');
        expect(auth.currentUser!.id, first);
      },
    );

    test('rejeita credenciais inválidas com mensagem amigável', () {
      final auth = DemoAuthService();
      expect(
        () => auth.signIn(email: 'ana@exemplo.com', password: '123'),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
