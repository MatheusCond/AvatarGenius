import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/login.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pages/auth_wrapper.dart';
// Adicione estas importações
import 'pages/historicoavatares.dart';
import 'pages/geradoravatar.dart';
import 'pages/chat_screen.dart'; // Nova tela de chat

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AvatarGenius',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          textTheme: const TextTheme(
              bodyLarge: TextStyle(fontFamily: 'Roboto'),
              bodyMedium: TextStyle(fontFamily: 'Roboto'))),
      initialRoute: '/',
      // Remova a rota '/chat' daqui
      routes: {
        '/': (context) => const AuthWrapper(),
        '/historico': (context) => const HistoricoAvataresScreen(),
        '/gerador': (context) => const GeradorAvatarScreen(),
      },
      onGenerateRoute: (settings) {
        // Adicione apenas esta verificação para a rota de chat
        if (settings.name == '/chat') {
          final args = settings.arguments as Map<String, dynamic>;

          return MaterialPageRoute(
            builder: (context) => ChatScreen(
              avatarImage: args['avatarImage'], // Parâmetro obrigatório
              profileData: args['profileData'], // Parâmetro obrigatório
            ),
          );
        }
        return null;
      },
    );
  }
}
