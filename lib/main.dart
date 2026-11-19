import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'bootstrap.dart';
import 'config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = await bootstrap(AppConfig.fromEnvironment());
  runApp(AvatarGeniusApp(services: services));
}
