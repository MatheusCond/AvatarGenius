import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../app_services.dart';
import '../../core/art/caricature_face.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/image_viewer.dart';
import '../../core/widgets/sticker.dart';
import '../../data/ai/ai_services.dart';
import '../../data/auth/auth_service.dart';
import '../auth/auth_fields.dart';
import '../chat/chat_page.dart';
import 'step_indicator.dart';

enum _Stage { photo, generating, result, personality }

/// Cria um avatar: foto → caricatura → nome e personalidade.
class GeneratorPage extends StatefulWidget {
  const GeneratorPage({super.key, required this.user, this.picker});

  final AppUser user;

  /// Injetável para testes.
  final ImagePicker? picker;

  @override
  State<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends State<GeneratorPage> {
  late final ImagePicker _picker = widget.picker ?? ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _personality = TextEditingController();

  _Stage _stage = _Stage.photo;
  Uint8List? _photo;
  String _photoMime = 'image/jpeg';
  String? _description;
  Uint8List? _caricature;
  String _status = '';
  String? _error;
  bool _saving = false;

  static const _personalityIdeas = [
    'Piadista, ri das próprias piadas',
    'Filósofo de boteco',
    'Coach motivacional exagerado',
    'Fofoqueiro, sabe da vida de todo mundo',
    'Narra tudo como jogo de futebol',
  ];

  AppServices get _services => AppScope.of(context);

  @override
  void dispose() {
    _name.dispose();
    _personality.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _photo = bytes;
        _photoMime = _mimeOf(file);
        _description = null;
        _caricature = null;
        _error = null;
      });
    } on Exception {
      if (mounted) {
        showMessage(
          context,
          source == ImageSource.camera
              ? 'Não foi possível abrir a câmera. Verifique a permissão do app.'
              : 'Não foi possível abrir suas fotos.',
        );
      }
    }
  }

  static String _mimeOf(XFile file) {
    if (file.mimeType != null) return file.mimeType!;
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  /// No modo demo, permite testar sem câmera nem foto: gera um "rosto"
  /// desenhado, com traços sorteados.
  Future<void> _useSampleFace() async {
    final bytes = await renderCaricaturePng(
      CaricatureTraits.fromSeed(DateTime.now().microsecondsSinceEpoch),
      backdrop: Palette.mist,
    );
    if (!mounted) return;
    setState(() {
      _photo = bytes;
      _photoMime = 'image/png';
      _description = null;
      _caricature = null;
      _error = null;
    });
  }

  Future<void> _generate() async {
    final photo = _photo;
    if (photo == null) return;
    setState(() {
      _stage = _Stage.generating;
      _error = null;
    });
    try {
      // Reaproveita a descrição ao pedir outra versão: só a imagem muda.
      if (_description == null) {
        setState(() => _status = 'Lendo os traços do seu rosto…');
        _description = await _services.faceDescriber.describe(
          photo,
          mimeType: _photoMime,
        );
      }
      if (!mounted) return;
      setState(() => _status = 'Desenhando a caricatura…');
      final caricature = await _services.caricatureGenerator.generate(
        _description!,
      );
      if (!mounted) return;
      setState(() {
        _caricature = caricature;
        _stage = _Stage.result;
      });
    } on AiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _stage = _caricature == null ? _Stage.photo : _Stage.result;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final avatar = await _services.avatars.create(
        widget.user.id,
        image: _caricature!,
        name: _name.text,
        personality: _personality.text,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) =>
              ChatPage(user: widget.user, avatar: avatar, image: _caricature!),
        ),
      );
    } on Exception {
      if (mounted) {
        setState(() => _saving = false);
        showMessage(
          context,
          'Não foi possível salvar o avatar. Tente de novo.',
        );
      }
    }
  }

  void _addIdea(String idea) {
    final current = _personality.text.trim();
    _personality.text = current.isEmpty
        ? idea
        : '$current, ${idea.toLowerCase()}';
    _personality.selection = TextSelection.collapsed(
      offset: _personality.text.length,
    );
  }

  int get _step => switch (_stage) {
    _Stage.photo || _Stage.generating => 0,
    _Stage.result => 1,
    _Stage.personality => 2,
  };

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _stage != _Stage.personality,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _stage = _Stage.result);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Novo avatar')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
            child: ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StepIndicator(
                    current: _step,
                    labels: const ['Foto', 'Caricatura', 'Personalidade'],
                  ),
                  const SizedBox(height: 28),
                  if (_services.config.demoMode && _step == 0) ...[
                    const DemoBanner(
                      message:
                          'Modo demo: a caricatura é desenhada no aparelho, '
                          'e cada foto gera um personagem diferente.',
                    ),
                    const SizedBox(height: 24),
                  ],
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: KeyedSubtree(
                      key: ValueKey(_stage),
                      child: switch (_stage) {
                        _Stage.photo || _Stage.generating => _buildPhotoStep(),
                        _Stage.result => _buildResultStep(),
                        _Stage.personality => _buildPersonalityStep(),
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoStep() {
    final textTheme = Theme.of(context).textTheme;
    final brand = BrandColors.of(context);
    final generating = _stage == _Stage.generating;
    final photo = _photo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Sticker(
                size: 220,
                tiltDegrees: -2,
                child: photo == null
                    ? Icon(
                        Icons.face_retouching_natural,
                        size: 88,
                        color: brand.muted,
                      )
                    : Image.memory(
                        photo,
                        fit: BoxFit.cover,
                        semanticLabel: 'Foto escolhida',
                      ),
              ),
              if (generating)
                SizedBox.square(
                  dimension: 244,
                  child: CircularProgressIndicator(
                    strokeWidth: 6,
                    strokeCap: StrokeCap.round,
                    semanticsLabel: _status,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        if (generating)
          Text(
            _status,
            style: textTheme.titleMedium,
            textAlign: TextAlign.center,
          )
        else if (photo == null) ...[
          Text('Comece por uma foto', style: textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Rosto de frente, bem iluminado e ocupando a maior parte da foto. '
            'Óculos e boné entram na caricatura.',
            style: textTheme.bodyMedium?.copyWith(color: brand.muted),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 16),
          _ErrorNote(message: _error!),
        ],
        if (!generating) ...[
          const SizedBox(height: 24),
          if (photo != null) ...[
            FilledButton.icon(
              onPressed: _generate,
              icon: const Icon(Icons.auto_fix_high),
              label: Text(
                _error == null ? 'Gerar caricatura' : 'Tentar de novo',
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(photo == null ? 'Tirar foto' : 'Outra foto'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galeria'),
                ),
              ),
            ],
          ),
          if (_services.config.demoMode && photo == null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _useSampleFace,
              icon: const Icon(Icons.casino_outlined),
              label: const Text('Usar um rosto de exemplo'),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildResultStep() {
    final textTheme = Theme.of(context).textTheme;
    final caricature = _caricature!;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // O único momento animado do app: a caricatura "cola" na página.
        TweenAnimationBuilder<double>(
          tween: Tween(begin: reduceMotion ? 1 : 0.6, end: 1),
          duration: Duration(milliseconds: reduceMotion ? 0 : 700),
          curve: Curves.elasticOut,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Center(
            child: GestureDetector(
              onTap: () => showImageViewer(
                context,
                caricature,
                semanticLabel: 'Caricatura gerada',
              ),
              child: Sticker(
                size: 248,
                tiltDegrees: 3,
                background: BrandColors.of(context).marker,
                child: Image.memory(
                  caricature,
                  fit: BoxFit.cover,
                  semanticLabel: 'Caricatura gerada. Toque para ampliar.',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text('Ficou com a sua cara?', style: textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Toque na imagem para ampliar. Se não gostou, peça outra versão a partir da mesma foto.',
          style: textTheme.bodyMedium?.copyWith(
            color: BrandColors.of(context).muted,
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          _ErrorNote(message: _error!),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => setState(() => _stage = _Stage.personality),
          child: const Text('Gostei, continuar'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _generate,
          icon: const Icon(Icons.refresh),
          label: const Text('Gerar outra versão'),
        ),
      ],
    );
  }

  Widget _buildPersonalityStep() {
    final textTheme = Theme.of(context).textTheme;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Sticker(
                size: 72,
                tiltDegrees: -3,
                child: Image.memory(_caricature!, fit: BoxFit.cover),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  'Dê vida ao personagem',
                  style: textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            maxLength: 40,
            decoration: const InputDecoration(
              labelText: 'Nome',
              hintText: 'Ex.: Zé Caricato',
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Dê um nome ao avatar.'
                : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _personality,
            minLines: 3,
            maxLines: 5,
            maxLength: 300,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Personalidade',
              hintText: 'Como ele fala, do que gosta, que manias tem',
              alignLabelWithHint: true,
            ),
            validator: (v) => (v == null || v.trim().length < 3)
                ? 'Descreva a personalidade em poucas palavras.'
                : null,
          ),
          const SizedBox(height: 4),
          Text('Sem ideias? Toque para usar:', style: textTheme.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final idea in _personalityIdeas)
                ActionChip(label: Text(idea), onPressed: () => _addIdea(idea)),
            ],
          ),
          const SizedBox(height: 28),
          BusyButton(
            label: 'Salvar e conversar',
            busy: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _ErrorNote extends StatelessWidget {
  const _ErrorNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.error, width: 2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: scheme.error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
