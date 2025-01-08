import 'package:flutter/material.dart';
import 'package:myapp/pages/historicoavatares.dart';

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
  bool _obscureSenha = true;
  bool _obscureConfirmarSenha = true;

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
                  onPressed: () {
                    // Aqui você pode adicionar a lógica de cadastro
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const HistoricoAvataresScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
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
