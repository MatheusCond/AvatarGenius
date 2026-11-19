import 'dart:async';

import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../../app_services.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/image_viewer.dart';
import '../../core/widgets/sticker.dart';
import '../../data/auth/auth_service.dart';
import '../../data/image_saver.dart';
import '../../data/models/avatar.dart';
import '../auth/auth_fields.dart';
import '../chat/chat_page.dart';
import '../generator/generator_page.dart';

/// Tela inicial de quem está logado: os avatares criados, como adesivos.
class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key, required this.user});

  final AppUser user;

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  List<Avatar>? _avatars;
  final _images = <String, Future<Uint8List?>>{};

  AppServices get _services => AppScope.of(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_avatars == null) _load();
  }

  Future<void> _load() async {
    final avatars = await _services.avatars.list(widget.user.id);
    if (mounted) setState(() => _avatars = avatars);
  }

  Future<Uint8List?> _imageOf(Avatar avatar) => _images.putIfAbsent(
    avatar.id,
    () => _services.avatars.loadImage(widget.user.id, avatar.id),
  );

  Future<void> _createAvatar() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => GeneratorPage(user: widget.user)),
    );
    await _load();
  }

  Future<void> _openChat(Avatar avatar) async {
    final image = await _imageOf(avatar);
    if (!mounted || image == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ChatPage(user: widget.user, avatar: avatar, image: image),
      ),
    );
  }

  Future<void> _saveToGallery(Avatar avatar) async {
    final image = await _imageOf(avatar);
    if (image == null) return;
    try {
      await _services.imageSaver.save(image, name: 'avatargenius_${avatar.id}');
      if (mounted) showMessage(context, 'Caricatura salva nas suas fotos.');
    } on ImageSaveException catch (e) {
      if (mounted) showMessage(context, e.message);
    }
  }

  Future<void> _delete(Avatar avatar) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir ${avatar.name}?'),
        content: const Text(
          'A caricatura e a conversa serão apagadas deste aparelho.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _services.avatars.delete(widget.user.id, avatar.id);
    _images.removeWhere((id, _) => id == avatar.id);
    await _load();
    if (mounted) showMessage(context, '${avatar.name} foi excluído.');
  }

  Future<void> _showDetails(Avatar avatar) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _AvatarSheet(
        avatar: avatar,
        image: _imageOf(avatar),
        canSave: _services.imageSaver.isSupported,
        onChat: () {
          Navigator.of(sheetContext).pop();
          unawaited(_openChat(avatar));
        },
        onSave: () => _saveToGallery(avatar),
        onDelete: () {
          Navigator.of(sheetContext).pop();
          unawaited(_delete(avatar));
        },
      ),
    );
  }

  Future<void> _signOut() async {
    await _services.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final avatars = _avatars;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seus avatares'),
        actions: [
          IconButton(
            tooltip: 'Sair da conta',
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: avatars == null || avatars.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _createAvatar,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Novo avatar'),
            ),
      body: SafeArea(
        child: switch (avatars) {
          null => const Center(child: CircularProgressIndicator()),
          [] => _EmptyGallery(
            demo: _services.config.demoMode,
            onCreate: _createAvatar,
          ),
          _ => RefreshIndicator(
            onRefresh: _load,
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 112),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 210,
                mainAxisSpacing: 28,
                crossAxisSpacing: 20,
                childAspectRatio: 0.78,
              ),
              itemCount: avatars.length,
              itemBuilder: (context, index) {
                final avatar = avatars[index];
                return _AvatarTile(
                  avatar: avatar,
                  image: _imageOf(avatar),
                  tilt: Sticker.tiltFor(index),
                  onTap: () => _showDetails(avatar),
                );
              },
            ),
          ),
        },
      ),
    );
  }
}

class _AvatarTile extends StatelessWidget {
  const _AvatarTile({
    required this.avatar,
    required this.image,
    required this.tilt,
    required this.onTap,
  });

  final Avatar avatar;
  final Future<Uint8List?> image;
  final double tilt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '${avatar.name}, criado em ${formatDate(avatar.createdAt)}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => Center(
                    child: Sticker(
                      size: constraints.biggest.shortestSide - 8,
                      tiltDegrees: tilt,
                      child: _AvatarImage(image: image),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                avatar.name,
                style: textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                formatDate(avatar.createdAt),
                style: textTheme.bodySmall?.copyWith(
                  color: BrandColors.of(context).muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({required this.image});

  final Future<Uint8List?> image;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: image,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) {
          return snapshot.connectionState == ConnectionState.done
              ? const Icon(Icons.broken_image_outlined)
              : const SizedBox.expand();
        }
        return Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true);
      },
    );
  }
}

class _AvatarSheet extends StatelessWidget {
  const _AvatarSheet({
    required this.avatar,
    required this.image,
    required this.canSave,
    required this.onChat,
    required this.onSave,
    required this.onDelete,
  });

  final Avatar avatar;
  final Future<Uint8List?> image;
  final bool canSave;
  final VoidCallback onChat;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: FutureBuilder<Uint8List?>(
                  future: image,
                  builder: (context, snapshot) => GestureDetector(
                    onTap: snapshot.data == null
                        ? null
                        : () => showImageViewer(
                            context,
                            snapshot.data!,
                            semanticLabel: 'Caricatura de ${avatar.name}',
                          ),
                    child: Sticker(
                      size: 168,
                      tiltDegrees: -2,
                      child: _AvatarImage(image: image),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                avatar.name,
                style: textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                avatar.personality,
                style: textTheme.bodyMedium?.copyWith(
                  color: BrandColors.of(context).muted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onChat,
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text('Conversar com ${avatar.name}'),
              ),
              if (canSave) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Salvar nas fotos'),
                ),
              ],
              const SizedBox(height: 8),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Excluir avatar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyGallery extends StatelessWidget {
  const _EmptyGallery({required this.demo, required this.onCreate});

  final bool demo;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ContentWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const BrandMark(size: 132),
            const SizedBox(height: 24),
            Text('Nenhum avatar ainda', style: textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Tire ou escolha uma foto do seu rosto. O AvatarGenius desenha a '
              'caricatura, você dá um nome e uma personalidade, e pode conversar com ela.',
              style: textTheme.bodyLarge?.copyWith(
                color: BrandColors.of(context).muted,
              ),
            ),
            if (demo) ...[
              const SizedBox(height: 20),
              const DemoBanner(
                message:
                    'Modo demo: a caricatura é desenhada no aparelho, sem IA.',
              ),
            ],
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Criar meu primeiro avatar'),
            ),
          ],
        ),
      ),
    );
  }
}
