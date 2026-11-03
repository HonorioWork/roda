# Restauração do Roda — 02/11/2026

## Causa

O GitHub Pages e o instalador continuavam disponíveis, mas o site apontava para um projeto Supabase removido. Por isso cadastro, login, mensagens, presença e geração de tokens de chamada deixaram de funcionar.

## Trabalho concluído

- Projeto Supabase disponível reativado e conectado ao cliente.
- Schema completo criado com RLS e privilégios explícitos para o Data API.
- Perfis automáticos após cadastro; servidores criam o dono e canais padrão.
- Mensagens, DMs, amizades, chamadas privadas, presença, cargos, denúncias, leitura e anexos restaurados.
- Bucket privado `message-files` criado com limite de 20 MB.
- Realtime ativado para mensagens e sinalização de chamadas.
- Edge Function `lk-token` publicada com autenticação e autorização para canais e chamadas privadas.
- Cache da PWA incrementado para evitar arquivos antigos.
- Perfis e preferências recebem um snapshot diário recuperável, totalmente independente do LiveKit e sem copiar senhas ou tokens.

## Separação do LiveKit

- O LiveKit recebe somente um identificador temporário, o nome exibido e permissões de entrada na sala.
- Contas, senhas, perfis, servidores, mensagens, amizades e arquivos continuam no Supabase.
- Uma falha do LiveKit impede apenas a mídia durante a chamada; não apaga, altera nem desconecta a conta.

## Validação

- Teste real: cadastro, perfil, login, atualização de status, criação de servidor, associação do dono, canais padrão e mensagem.
- Teste visual automatizado: temas e larguras 360, 390, 768, 1280, 1920 e 2560 px, sem erro JavaScript ou rolagem horizontal.
- Consultas de segurança confirmaram RLS em todas as tabelas do Roda e ausência de acesso anônimo às funções internas.

## Pendente externo

- `lk-token` está ativo, porém o projeto restaurado ainda precisa receber `LK_URL`, `LK_KEY` e `LK_SECRET` de um servidor LiveKit. Sem esses três segredos, voz, vídeo e tela retornam uma mensagem de configuração em vez de falhar silenciosamente.
- Contas e conteúdo que existiam somente no projeto Supabase removido não estavam presentes no projeto recuperado e não puderam ser restaurados.
