# AvatarGenius (Avataria) — app original do TCC

Este é o app Flutter que deu origem ao projeto. Ele fica aqui só como registro
histórico: **não é mais mantido** e não faz parte do jogo "Quem é a IA?".

## O que ele fazia

1. Login e cadastro com Firebase Auth.
2. O usuário tirava uma selfie (`image_picker`).
3. O Gemini (`gemini-2.0-flash`) descrevia a pessoa da foto.
4. O DALL-E 3 gerava um avatar a partir dessa descrição.
5. Dava para criar um chatbot com nome e personalidade a partir do avatar e
   conversar com ele (Gemini).
6. Avatares e conversas ficavam salvos no `SharedPreferences` do aparelho.

## Por que foi aposentado

- As chaves de API eram carregadas de um `.env` empacotado no app, ou seja,
  iam parar dentro do APK. Qualquer pessoa podia extrair as chaves.
- Os dados ficavam só no aparelho, sem backend.
- Não havia testes nem README.

O jogo novo resolve isso: as chaves ficam só no servidor e os dados vão para o
PostgreSQL. A história completa está no [README principal](../../README.md).

## Observação sobre as chaves do Firebase

Os arquivos `lib/firebase_options.dart` e `android/app/google-services.json`
tinham as chaves de API do projeto Firebase. Nesta cópia elas foram trocadas
por placeholders (`REPLACE_WITH_...`). As chaves originais continuam no
histórico do Git. Por isso o projeto Firebase deve ser desativado, ou as chaves
devem ser restringidas no Google Cloud Console.

Para rodar este app de novo seria preciso gerar a configuração com
`flutterfire configure` e criar um `.env` com `GEMINI_API_KEY` e
`DALL_E_API_KEY`.
