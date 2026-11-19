import 'package:material_ui/material_ui.dart';

import '../../data/auth/auth_service.dart';

class EmailField extends StatelessWidget {
  const EmailField({
    super.key,
    required this.controller,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      autocorrect: false,
      decoration: const InputDecoration(
        labelText: 'Email',
        prefixIcon: Icon(Icons.alternate_email),
      ),
      validator: Credentials.validateEmail,
    );
  }
}

/// Campo de senha com botão para mostrar ou esconder o texto.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'Senha',
    this.validator = Credentials.validatePassword,
    this.isNewPassword = false,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String> validator;
  final bool isNewPassword;
  final TextInputAction textInputAction;
  final VoidCallback? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscured,
      textInputAction: widget.textInputAction,
      autofillHints: [
        if (widget.isNewPassword)
          AutofillHints.newPassword
        else
          AutofillHints.password,
      ],
      onFieldSubmitted: (_) => widget.onSubmitted?.call(),
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: _obscured ? 'Mostrar senha' : 'Esconder senha',
          icon: Icon(
            _obscured
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: () => setState(() => _obscured = !_obscured),
        ),
      ),
      validator: widget.validator,
    );
  }
}

/// Botão principal que vira um indicador de progresso durante o envio.
class BusyButton extends StatelessWidget {
  const BusyButton({
    super.key,
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      child: busy
          ? SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Theme.of(context).colorScheme.onSurface,
                semanticsLabel: 'Enviando',
              ),
            )
          : Text(label),
    );
  }
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
