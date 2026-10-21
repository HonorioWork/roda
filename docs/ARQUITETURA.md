# Arquitetura do Roda atual

- **Interface:** aplicação web estática em `index.html`, sem etapa de build.
- **Identidade e dados:** Supabase Auth, Postgres, RLS e Realtime.
- **Voz, câmera e tela:** LiveKit Cloud, com tokens emitidos pela Edge Function `lk-token`.
- **Aplicativo Windows:** WebView2 abre o site público e verifica `updates/windows.json` ao iniciar.
- **Publicação:** GitHub Pages em `https://honoriowork.github.io/roda/`.

As preferências de conta ficam em `user_settings`. Identificadores de dispositivos de áudio e vídeo ficam somente no aparelho, em armazenamento local. O fluxo legado de servidores, canais, chat e voz continua sendo usado para compatibilidade.

