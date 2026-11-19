# Changelog

## 2.0.0 (novembro de 2026)

Revisão completa do app. A v1 tinha parado de funcionar porque os dois modelos
de IA que ela usava foram desligados pelos provedores.

### Corrigido

- **IA fora do ar.** O `gemini-2.0-flash` e o `dall-e-3` foram desligados em
  2026. O app agora usa `gemini-3.8-flash` e `gpt-image-2.6-flare`, ambos
  configuráveis sem mexer no código.
- **Chaves de API dentro do APK.** O `.env` era declarado como asset no
  `pubspec.yaml` e ia empacotado no app. Além disso, sem o arquivo o projeto
  nem compilava depois de um clone. As chaves agora entram por
  `--dart-define-from-file`.
- **Chave do Gemini na URL.** Ia como `?key=` e podia aparecer em logs. Agora
  vai no header `x-goog-api-key`.
- **Avatares compartilhados entre contas.** Tudo ficava no aparelho sem
  separação por usuário: quem entrasse com outra conta via a galeria da
  anterior.
- **Excluir deixava lixo.** Apagar um avatar removia só a imagem; o perfil e a
  conversa ficavam ocupando espaço.
- **Erro salvo como fala do personagem.** Uma falha da API entrava no histórico
  como se o avatar tivesse dito "Erro ao gerar resposta".
- **Mensagens em branco e envios duplicados.** Era possível enviar só espaços e
  disparar várias mensagens enquanto a resposta não chegava.
- **Resposta bloqueada travava o chat.** Quando o Gemini recusava o conteúdo, o
  app tentava ler um campo inexistente e caía no erro genérico.
- **Navegação de login inconsistente.** Login e cadastro empurravam telas por
  conta própria, em paralelo ao `AuthWrapper`, o que deixava telas antigas na
  pilha.
- **Build Android quebrado em versões atuais do Flutter.** O Gradle forçava o
  AGP 7.3 nos subprojetos, Java 8 e um patch local do `image_gallery_saver`
  (pacote abandonado). Migrado para o template atual em Kotlin DSL e para o
  pacote `gal`.
- **Lixo no repositório.** Removidos um `venv` do Python, um arquivo chamado
  `et --soft <commit-hash>` (saída de terminal commitada por engano, que
  impedia o clone no Windows), código de teste de API que imprimia parte da
  chave e o teste padrão do contador, que não passava.
- **`web/index.html`** tinha scripts soltos depois de `</html>`.

### Novo

- Modo demo (`--dart-define=DEMO_MODE=true`): roda sem Firebase e sem chaves,
  com caricaturas desenhadas no aparelho.
- Recuperação de senha.
- Gerar outra versão da caricatura sem reenviar a foto.
- Sugestões de personalidade e de primeiras mensagens.
- Indicador de "digitando" e envio com Enter.
- Detecção de foto sem rosto.
- Migração automática dos dados salvos pela v1.
- Modo escuro e layout responsivo para tablet e navegador.
- Interface redesenhada com identidade visual própria.
- 38 testes automatizados e CI no GitHub Actions.

### Por dentro

- Camadas separadas (`features`, `data`, `core`) com interfaces para auth, IA
  e armazenamento, e injeção de dependências via `InheritedWidget`.
- Lints estritos (`strict-casts`, `strict-raw-types`, `avoid_dynamic_calls` e
  outros).
- Imagens salvas como arquivos PNG em vez de base64 no SharedPreferences.
- `photo_view` trocado pelo `InteractiveViewer` nativo, e
  `package:flutter/material.dart` pelo `material_ui`.

## 1.0.0 (2025)

Primeira versão: login com Firebase, caricatura com Gemini e DALL·E 3,
histórico local e chat com o avatar.
