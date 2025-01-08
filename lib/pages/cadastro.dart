import 'package:flutter/material.dart';
import 'package:myapp/pages/historicoavatares.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({Key? key}) : super(key: key);

  @override
  _CadastroScreenState createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmarSenhaController =
      TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _obscureSenha = true;
  bool _obscureConfirmarSenha = true;
  bool _isLoading = false;

  Future<void> _realizarCadastro() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text;
    final confirmarSenha = _confirmarSenhaController.text;

    // Validações
    if (email.isEmpty || senha.isEmpty || confirmarSenha.isEmpty) {
      _mostrarErro('Preencha todos os campos');
      return;
    }

    if (senha != confirmarSenha) {
      _mostrarErro('As senhas não coincidem');
      return;
    }

    if (senha.length < 6) {
      _mostrarErro('A senha deve ter pelo menos 6 caracteres');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      if (userCredential.user != null) {
        // Cadastro bem sucedido
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const HistoricoAvataresScreen()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String mensagem = 'Erro ao realizar cadastro';

      if (e.code == 'email-already-in-use') {
        mensagem = 'Este email já está em uso';
      } else if (e.code == 'invalid-email') {
        mensagem = 'Email inválido';
      } else if (e.code == 'weak-password') {
        mensagem = 'Senha muito fraca';
      }

      _mostrarErro(mensagem);
    } catch (e) {
      _mostrarErro('Erro ao realizar cadastro');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cadastro',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF1F1F1),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/backgroundai.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.5), BlendMode.darken),
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Seu email de cadastro',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _senhaController,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    hintText: 'Sua senha',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureSenha
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () {
                        setState(() {
                          _obscureSenha = !_obscureSenha;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscureSenha,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmarSenhaController,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Senha',
                    hintText: 'Confirme sua senha',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmarSenha
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmarSenha = !_obscureConfirmarSenha;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscureConfirmarSenha,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _realizarCadastro,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Cadastrar',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
