# Estrutura de arquivos

## Regra geral

Mantenha na raiz somente os arquivos necessários para publicar e iniciar o site. Imagens, estilos, migrations, instaladores antigos e documentação devem ficar nas pastas próprias.

## Destinos

- Novos estilos: `assets/styles/`.
- Novos ícones e imagens da marca: `icons/`.
- Novas migrations: `supabase/migrations/`, usando o padrão `AAAAMMDD_descricao.sql`.
- Instalador atual: `downloads/Roda-Setup-X.Y.Z.msi`.
- Instaladores substituídos: `downloads/anteriores/`.
- Documentos técnicos: `docs/`.
- Scripts de manutenção: `ferramentas/`.
- Metadados do atualizador: `updates/`.

Não mova `index.html`, `manifest.webmanifest`, `sw.js`, `.nojekyll`, `README.md` ou `CHANGELOG.md` sem revisar a publicação do GitHub Pages.
