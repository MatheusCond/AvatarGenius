import 'package:material_ui/material_ui.dart';

import '../../app_services.dart';
import '../../core/widgets/brand.dart';
import '../../data/auth/auth_service.dart';
import '../gallery/gallery_page.dart';
import 'login_page.dart';

/// Mostra a galeria para quem está logado e o login para quem não está.
///
/// É o único lugar que decide isso: login, cadastro e logout só mudam o
/// estado de autenticação, sem navegar por conta própria.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).auth;
    return StreamBuilder<AppUser?>(
      stream: auth.authStateChanges(),
      initialData: auth.currentUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return const Scaffold(body: Center(child: BrandMark(size: 120)));
        }
        final user = snapshot.data;
        if (user == null) return const LoginPage();
        return GalleryPage(key: ValueKey(user.id), user: user);
      },
    );
  }
}
