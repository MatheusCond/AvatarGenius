/// Usuário autenticado, independente do provedor de login.
class AppUser {
  const AppUser({required this.id, this.email});

  final String id;
  final String? email;
}

/// Erro de autenticação com uma mensagem pronta para mostrar na tela.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}

/// Contrato de autenticação usado pela interface.
///
/// A implementação real usa Firebase ([FirebaseAuthService]); o modo demo
/// usa [DemoAuthService], que não sai do aparelho.
abstract interface class AuthService {
  /// Emite o usuário atual ao assinar e a cada login ou logout.
  Stream<AppUser?> authStateChanges();

  AppUser? get currentUser;

  Future<void> signIn({required String email, required String password});

  Future<void> signUp({required String email, required String password});

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}

/// Validações compartilhadas pelos formulários e pelos serviços.
abstract final class Credentials {
  static const minPasswordLength = 6;

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Informe seu email.';
    if (!_email.hasMatch(email)) return 'Esse email não parece válido.';
    return null;
  }

  static String? validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Informe sua senha.';
    if (password.length < minPasswordLength) {
      return 'A senha precisa de pelo menos $minPasswordLength caracteres.';
    }
    return null;
  }
}

/// Traduz os códigos de erro do Firebase Auth para mensagens em português.
///
/// Desde que o Firebase ativou a proteção contra enumeração de emails,
/// usuário inexistente e senha errada chegam juntos como
/// `invalid-credential`.
String authErrorMessage(String code) {
  switch (code) {
    case 'invalid-credential':
    case 'wrong-password':
    case 'user-not-found':
    case 'invalid-login-credentials':
      return 'Email ou senha incorretos.';
    case 'invalid-email':
      return 'Esse email não parece válido.';
    case 'user-disabled':
      return 'Esta conta foi desativada.';
    case 'email-already-in-use':
      return 'Já existe uma conta com esse email. Entre ou recupere a senha.';
    case 'weak-password':
      return 'Senha fraca. Use pelo menos 6 caracteres, misturando letras e números.';
    case 'too-many-requests':
      return 'Muitas tentativas seguidas. Espere alguns minutos e tente de novo.';
    case 'network-request-failed':
      return 'Sem conexão com a internet. Verifique a rede e tente de novo.';
    case 'operation-not-allowed':
      return 'Login por email e senha está desativado neste projeto Firebase.';
    default:
      return 'Não foi possível concluir agora. Tente de novo em instantes.';
  }
}
