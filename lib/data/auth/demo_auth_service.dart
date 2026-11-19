import 'dart:async';

import 'auth_service.dart';

/// Login local para o modo demo e para os testes: aceita qualquer email
/// válido com senha de 6+ caracteres e nunca sai do aparelho.
class DemoAuthService implements AuthService {
  DemoAuthService({AppUser? initialUser}) : _current = initialUser;

  final _changes = StreamController<AppUser?>.broadcast();
  AppUser? _current;

  /// Emite o usuário atual assim que alguém assina e depois cada mudança.
  /// A inscrição em [_changes] acontece já no `listen`, para não perder
  /// eventos (um `async*` só começaria a ouvir no próximo microtask).
  @override
  Stream<AppUser?> authStateChanges() {
    StreamSubscription<AppUser?>? changes;
    late final StreamController<AppUser?> controller;
    controller = StreamController<AppUser?>(
      onListen: () {
        controller.add(_current);
        changes = _changes.stream.listen(controller.add);
      },
      onCancel: () => changes?.cancel(),
    );
    return controller.stream;
  }

  @override
  AppUser? get currentUser => _current;

  @override
  Future<void> signIn({required String email, required String password}) async {
    _validate(email, password);
    _emit(AppUser(id: _idFor(email), email: email.trim()));
  }

  @override
  Future<void> signUp({required String email, required String password}) =>
      signIn(email: email, password: password);

  @override
  Future<void> sendPasswordReset(String email) async {
    final error = Credentials.validateEmail(email);
    if (error != null) throw AuthException(error);
  }

  @override
  Future<void> signOut() async => _emit(null);

  void _emit(AppUser? user) {
    _current = user;
    _changes.add(user);
  }

  static void _validate(String email, String password) {
    final error =
        Credentials.validateEmail(email) ??
        Credentials.validatePassword(password);
    if (error != null) throw AuthException(error);
  }

  /// Id estável por email, para cada conta demo ter a própria galeria.
  /// Usa FNV-1a em vez de `hashCode`, que não é garantido entre plataformas.
  static String _idFor(String email) {
    var hash = 0x811c9dc5;
    for (final unit in email.trim().toLowerCase().codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    return 'demo-${hash.toRadixString(16)}';
  }
}
