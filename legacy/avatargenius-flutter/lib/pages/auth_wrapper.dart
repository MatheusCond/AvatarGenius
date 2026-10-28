import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:avataria/pages/historicoavatares.dart';
import 'package:avataria/pages/login.dart'; // Seu arquivo de login atual

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Verificando o estado de carregamento
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Se o usuário está logado, vai para a tela de histórico
        if (snapshot.hasData) {
          return const HistoricoAvataresScreen();
        }

        // Se não está logado, mostra a tela de login
        return const LoginScreen();
      },
    );
  }
}