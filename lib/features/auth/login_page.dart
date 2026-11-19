import 'package:material_ui/material_ui.dart';

import '../../app_services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand.dart';
import '../../data/auth/auth_service.dart';
import 'auth_fields.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await AppScope.of(
        context,
      ).auth.signIn(email: _email.text, password: _password.text);
      // O AuthGate troca para a galeria quando o login emite o usuário.
    } on AuthException catch (e) {
      if (mounted) showMessage(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = await showDialog<String>(
      context: context,
      builder: (_) => _ResetPasswordDialog(initialEmail: _email.text.trim()),
    );
    if (email == null || !mounted) return;
    try {
      await AppScope.of(context).auth.sendPasswordReset(email);
      if (mounted) {
        showMessage(
          context,
          'Enviamos um link para redefinir a senha em $email.',
        );
      }
    } on AuthException catch (e) {
      if (mounted) showMessage(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final textTheme = Theme.of(context).textTheme;
    final brand = BrandColors.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: ContentWidth(
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: BrandMark(size: 148),
                    ),
                    const SizedBox(height: 20),
                    const Wordmark(size: 44),
                    const SizedBox(height: 8),
                    Text(
                      'Transforme uma selfie numa caricatura e converse com ela.',
                      style: textTheme.bodyLarge?.copyWith(color: brand.muted),
                    ),
                    if (services.config.demoMode) ...[
                      const SizedBox(height: 20),
                      const DemoBanner(
                        message:
                            'Modo demo: qualquer email com senha de 6 ou '
                            'mais caracteres entra, e nada sai do aparelho.',
                      ),
                    ],
                    const SizedBox(height: 32),
                    EmailField(controller: _email),
                    const SizedBox(height: 14),
                    PasswordField(controller: _password, onSubmitted: _signIn),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _busy ? null : _resetPassword,
                        child: const Text('Esqueci minha senha'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    BusyButton(
                      label: 'Entrar',
                      busy: _busy,
                      onPressed: _signIn,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Ainda não tem conta?',
                          style: textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const SignupPage(),
                                  ),
                                ),
                          child: const Text('Criar conta'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog({required this.initialEmail});

  final String initialEmail;

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_email.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Redefinir senha'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enviaremos um link para você criar uma senha nova.'),
            const SizedBox(height: 16),
            EmailField(controller: _email, autofocus: true),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(onPressed: _submit, child: const Text('Enviar link')),
      ],
    );
  }
}
