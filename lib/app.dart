import 'package:material_ui/material_ui.dart';

import 'app_services.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_gate.dart';

class AvatarGeniusApp extends StatelessWidget {
  const AvatarGeniusApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: services,
      child: MaterialApp(
        title: 'AvatarGenius',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const AuthGate(),
      ),
    );
  }
}
