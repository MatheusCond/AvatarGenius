/// Configuração lida em tempo de compilação via `--dart-define` ou
/// `--dart-define-from-file=env.json`.
///
/// As chaves nunca ficam no código-fonte nem em assets do app.
class AppConfig {
  const AppConfig({
    this.geminiApiKey = '',
    this.openAiApiKey = '',
    this.geminiModel = defaultGeminiModel,
    this.imageModel = defaultImageModel,
    this.demoMode = false,
  });

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      geminiApiKey: String.fromEnvironment('GEMINI_API_KEY'),
      openAiApiKey: String.fromEnvironment('OPENAI_API_KEY'),
      geminiModel: String.fromEnvironment(
        'GEMINI_MODEL',
        defaultValue: defaultGeminiModel,
      ),
      imageModel: String.fromEnvironment(
        'OPENAI_IMAGE_MODEL',
        defaultValue: defaultImageModel,
      ),
      demoMode: bool.fromEnvironment('DEMO_MODE'),
    );
  }

  /// Modelo multimodal estável do Gemini (lê a foto e conduz o chat).
  static const defaultGeminiModel = 'gemini-3.8-flash';

  /// Modelo de geração de imagem da OpenAI. O `dall-e-3`, usado na v1,
  /// foi desligado pela OpenAI em maio de 2026.
  static const defaultImageModel = 'gpt-image-2.6-flare';

  final String geminiApiKey;
  final String openAiApiKey;
  final String geminiModel;
  final String imageModel;

  /// Roda o app sem Firebase e sem chamadas pagas de IA: login local,
  /// caricatura desenhada no aparelho e respostas de chat simuladas.
  final bool demoMode;
}
