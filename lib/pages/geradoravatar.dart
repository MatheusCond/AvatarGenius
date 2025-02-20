import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/dall_e_service.dart';
import 'package:myapp/gemini_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';


class GeradorAvatarScreen extends StatefulWidget {
  const GeradorAvatarScreen({Key? key}) : super(key: key);

  @override
  State<GeradorAvatarScreen> createState() => _GeradorAvatarScreenState();
}

class _GeradorAvatarScreenState extends State<GeradorAvatarScreen> {
  XFile? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  Uint8List? _generatedAvatar;
  bool _isLoading = false;
  String _statusMessage = '';
  
  late final GeminiService _geminiService;
  late final DallEService _dallEService;
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }
  
  Future<void> _initializeServices() async {
    final geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final dallEApiKey = dotenv.env['DALL_E_API_KEY'] ?? '';
    
    _geminiService = GeminiService(apiKey: geminiApiKey);
    _dallEService = DallEService(apiKey: dallEApiKey);
  }

  Future<void> _getImage(ImageSource source) async {
    setState(() {
      _isLoading = false;
      _statusMessage = '';
      _generatedAvatar = null;
      _selectedImageBytes = null;
      _selectedImageFile = null;
    });
    
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? imageFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
      );
      
      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        
        setState(() {
          _selectedImageFile = imageFile;
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      _showErrorMessage('Não foi possível selecionar a imagem: $e');
    }
  }
  
  Future<void> _generateAvatar() async {
    if (_selectedImageBytes == null) {
      _showErrorMessage('Selecione uma imagem primeiro');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _statusMessage = 'Analisando imagem...';
    });
    
    try {
      final String description = await _geminiService.generateImageDescription(_selectedImageBytes!);
      
      setState(() {
        _statusMessage = 'Criando avatar baseado na descrição...';
      });
      
      final Uint8List avatarImage = await _dallEService.generateAvatar(description);
      
      setState(() {
        _generatedAvatar = avatarImage;
        _isLoading = false;
        _statusMessage = 'Avatar gerado com sucesso!';
      });
      
      _saveGeneratedAvatar(avatarImage);
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('Erro ao gerar avatar: $e');
    }
  }
  
  Future<void> _saveGeneratedAvatar(Uint8List avatarData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString('avatar_$timestamp', base64Encode(avatarData));
    } catch (e) {
      debugPrint('Erro ao salvar avatar: $e');
    }
  }
  
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
    setState(() {
      _statusMessage = 'Ocorreu um erro';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gerar Avatar',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/backgroundhistorico.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.6),
              BlendMode.darken,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : _generatedAvatar != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: Image.memory(
                              _generatedAvatar!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : _selectedImageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: Image.memory(
                                  _selectedImageBytes!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.person,
                                  size: 100,
                                  color: Colors.white,
                                ),
                              ),
              ),
              
              if (_statusMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    _statusMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _getImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text(
                        'Câmera',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _getImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text(
                        'Galeria',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              if (_selectedImageBytes != null && !_isLoading)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _generateAvatar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Gerar Avatar Caricato',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                
              if (_generatedAvatar != null && !_isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, _generatedAvatar);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Usar Este Avatar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}