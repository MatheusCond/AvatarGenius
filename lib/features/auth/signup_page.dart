import 'package:material_ui/material_ui.dart';

import '../../app_services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand.dart';
import '../../data/auth/auth_service.dart';
import 'auth_fields.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await AppScope.of(
        context,
      ).auth.signUp(email: _email.text, password: _password.text);
      // Volta para a raiz, onde o AuthGate já mostra a galeria.
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthException catch (e) {
      if (mounted) showMessage(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: ContentWidth(
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Seus avatares e conversas ficam guardados nesta conta.',
                      style: textTheme.bodyLarge?.copyWith(
                        color: BrandColors.of(context).muted,
                      ),
                    ),
                    const SizedBox(height: 28),
                    EmailField(controller: _email),
                    const SizedBox(height: 14),
                    PasswordField(
                      controller: _password,
                      isNewPassword: true,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),
                    PasswordField(
                      controller: _confirm,
                      label: 'Repita a senha',
                      isNewPassword: true,
                      onSubmitted: _signUp,
                      validator: (value) => value != _password.text
                          ? 'As senhas não são iguais.'
                          : null,
                    ),
                    const SizedBox(height: 28),
                    BusyButton(
                      label: 'Criar conta',
                      busy: _busy,
                      onPressed: _signUp,
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
