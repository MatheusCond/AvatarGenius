import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:avataria/pages/login.dart';
import 'geradoravatar.dart';
import 'package:photo_view/photo_view.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:avataria/utils/device_info.dart';

class HistoricoAvataresScreen extends StatefulWidget {
  const HistoricoAvataresScreen({Key? key}) : super(key: key);

  @override
  State<HistoricoAvataresScreen> createState() =>
      _HistoricoAvataresScreenState();
}

class _HistoricoAvataresScreenState extends State<HistoricoAvataresScreen> {
  List<AvatarItem> _avatares = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarAvatares();
  }

  Future<void> _carregarAvatares() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      // Filtrar apenas as chaves relacionadas aos avatares
      final avatarKeys =
          keys.where((key) => key.startsWith('avatar_')).toList();

      // Ordenar por data (mais recente primeiro)
      avatarKeys.sort((a, b) => b.compareTo(a));

      List<AvatarItem> avatares = [];

      for (var key in avatarKeys) {
        final avatarString = prefs.getString(key);
        if (avatarString != null) {
          try {
            final timestamp = int.parse(key.split('_')[1]);
            final data = DateTime.fromMillisecondsSinceEpoch(timestamp);

            avatares.add(AvatarItem(
              id: key,
              imageData: base64Decode(avatarString),
              data: data,
            ));
          } catch (e) {
            debugPrint('Erro ao decodificar avatar: $e');
          }
        }
      }

      setState(() {
        _avatares = avatares;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar avatares: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removerAvatar(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(id);

      setState(() {
        _avatares.removeWhere((avatar) => avatar.id == id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar removido com sucesso')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao remover avatar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Histórico de Avatares',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.black87),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/backgroundhistorico.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.darken,
            ),
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white))
            : _avatares.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhum avatar encontrado.\nGere seu primeiro avatar!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _avatares.length,
                      itemBuilder: (context, index) {
                        final avatar = _avatares[index];
                        return _buildAvatarCard(avatar);
                      },
                    ),
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GeradorAvatarScreen(),
            ),
          );

          if (result != null) {
            // Se um novo avatar foi criado, recarregue a lista
            _carregarAvatares();
          }
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

// Adicione este método na classe _HistoricoAvataresScreenState
  Future<void> _salvarImagem(Uint8List bytes) async {
    try {
      // --------------------------------------------
      // 1. Verifica a versão do Android e define a permissão
      // --------------------------------------------
      Permission permission;

      if (await DeviceInfo.isAndroid13OrAbove()) {
        permission = Permission.photos; // Android 13+
      } else {
        permission = Permission.storage; // Android <= 12
      }

      // --------------------------------------------
      // 2. Solicita a permissão
      // --------------------------------------------
      final PermissionStatus status = await permission.request();

      // --------------------------------------------
      // 3. Trata permissão negada
      // --------------------------------------------
      if (!status.isGranted) {
        if (status.isPermanentlyDenied) {
          // Mostra diálogo para abrir configurações
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Permissão necessária'),
              content:
                  const Text('Habilite a permissão nas configurações do app'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    openAppSettings(); // Abre configurações do app
                    Navigator.pop(context);
                  },
                  child: const Text('Abrir Configurações'),
                ),
              ],
            ),
          );
        }
        throw Exception('Permissão de armazenamento negada');
      }

      // --------------------------------------------
      // 4. Salva a imagem na galeria
      // --------------------------------------------
      final result = await ImageGallerySaver.saveImage(
        bytes,
        quality: 100,
        name: "avatar_${DateTime.now().millisecondsSinceEpoch}", // Nome único
      );

      // --------------------------------------------
      // 5. Mostra feedback para o usuário
      // --------------------------------------------
      if (result['isSuccess']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagem salva na galeria!')),
        );
      } else {
        throw Exception('Falha ao salvar imagem: ${result['errorMessage']}');
      }
    } catch (e) {
      // --------------------------------------------
      // 6. Trata erros (incluindo permissões negadas)
      // --------------------------------------------
      if (e.toString().contains('denied')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Permissão negada! Habilite nas configurações'),
            action: SnackBarAction(
              label: 'Configurações',
              onPressed: openAppSettings, // Abre configurações diretamente
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar imagem: $e')),
        );
      }
    }
  }

// Modifique o _buildAvatarCard para adicionar a funcionalidade
  Widget _buildAvatarCard(AvatarItem avatar) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: Colors.white.withOpacity(0.8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      body: Stack(
                        children: [
                          PhotoView(
                            imageProvider: MemoryImage(avatar.imageData),
                            minScale: PhotoViewComputedScale.contained,
                            maxScale: PhotoViewComputedScale.covered * 2,
                          ),
                          SafeArea(
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.memory(
                  avatar.imageData,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(avatar.data),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.file_download, color: Colors.green),
                      onPressed: () => _salvarImagem(avatar.imageData),
                      tooltip: 'Baixar imagem',
                      iconSize: 22,
                    ),
                    IconButton(
                      icon: const Icon(Icons.person, color: Colors.blue),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Avatar definido como perfil!')),
                        );
                      },
                      tooltip: 'Usar como perfil',
                      iconSize: 22,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removerAvatar(avatar.id),
                      tooltip: 'Remover avatar',
                      iconSize: 22,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime data) {
    return '${data.day}/${data.month}/${data.year} ${data.hour}:${data.minute.toString().padLeft(2, '0')}';
  }
}

class AvatarItem {
  final String id;
  final Uint8List imageData;
  final DateTime data;

  AvatarItem({
    required this.id,
    required this.imageData,
    required this.data,
  });
}
