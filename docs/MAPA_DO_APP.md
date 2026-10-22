# Mapa do app Roda

## Stack e execução
- App estático sem bundler: `index.html`, CSS e JavaScript nativos.
- Supabase JS 2.45.4: Auth, Postgres, Realtime e Edge Function `lk-token`.
- LiveKit Client 2.5.7: voz, câmera e compartilhamento de tela.
- PWA: `manifest.webmanifest` e `sw.js`; publicação pelo GitHub Pages.
- Abrir localmente: `iniciar.bat`; publicação: copiar arquivos públicos para `publicacao-online/` e enviar a `main`.
- Não há scripts separados de build, lint, typecheck ou testes; validação é `node --check`, `git diff --check` e QA no navegador.

## Estrutura
- `index.html`: toda a interface e os fluxos de autenticação, servidores, chat, social, configurações e chamadas.
- `theme.css`: tokens e estilos compartilhados adicionados por este lote.
- `sw.js`: cache do shell instalado.
- `supabase/*.sql`: schema inicial e migrations aditivas com RLS.
- `supabase/functions/lk-token/`: autorização das salas LiveKit.
- `publicacao-online/`: checkout publicado em `HonorioWork/roda`.
- `docs/`: arquitetura, mapa, plano e relatório do lote.

## Interface e estado
- Layout principal: `#app`; sidebar: `#side`, `#srvs` e `#chn`; membros: `#mem`.
- Início: `showHome`; amigos: `showFriends`; canais: `pickSrv`, `drawChs`, `pickCh`.
- Chat: `textView`, `msgNode`; DM: `openDM`.
- Voz/LiveKit: `voiceView`, `join`, `draw`, `voice-dock`; presença externa: `call_presence`.
- Estado global fica em variáveis no script; preferências sincronizadas ficam em `user_settings.settings` JSON.
- Dispositivos e preferências específicas do aparelho ficam em `localStorage`.
- Dados principais: `profiles`, `servers`, `members`, `channels`, `messages`, `friendships`, `direct_messages`, `call_presence`, `private_calls` e `reports`.

## Tema e tokens
- `theme.css` centraliza cores, espaços 4/8/12/16/24/32, raios, sombras, tipografia e alturas de toque.
- Componentes tocados neste lote usam `--color-*`, `--space-*`, `--radius-*`, `--shadow-*` e `--font-*`.
- O modo claro usa `.theme-light`; alto contraste e movimento reduzido já são classes globais.
- CSS respeita `prefers-reduced-motion` e áreas seguras com `env(safe-area-inset-*)`.

## Flags e larguras
- Não existe serviço de feature flags; recursos conservadores usam preferências em `user_settings` ou `localStorage`.
- Breakpoints existentes: 700, 900, 1000 e 1500 px; o lote adiciona comportamento móvel abaixo de 768 px.
- Matriz de QA: 360, 390, 768, 1280, 1920 e 2560 px, em tema claro e escuro.
