# Roda

Roda é um app de comunidade com mensagens, canais, voz, vídeo e compartilhamento de tela.

## Estrutura

- `index.html` — aplicação web principal.
- `assets/styles/` — temas e tokens visuais.
- `icons/` — logotipos, favicon e ícones da interface/PWA.
- `supabase/migrations/` — migrations SQL em ordem cronológica.
- `aplicativo-windows/` — código e artefatos do aplicativo para Windows.
- `installer-windows/` — definição do instalador MSI.
- `downloads/` — página pública e instalador atual.
- `downloads/anteriores/` — instaladores antigos preservados para referência.
- `updates/` — metadados usados pela atualização automática.
- `ferramentas/` — scripts de manutenção e assinatura.
- `docs/` — arquitetura, implantação, conformidade e relatórios.

O site é publicado pelo GitHub Pages. O aplicativo para Windows carrega a versão web publicada e verifica atualizações ao abrir.

Consulte [`docs/ESTRUTURA_DE_ARQUIVOS.md`](docs/ESTRUTURA_DE_ARQUIVOS.md) antes de adicionar arquivos novos.
