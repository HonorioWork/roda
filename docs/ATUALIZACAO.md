# Aplicar esta atualização

1. Preserve um backup do banco no painel do Supabase.
2. Execute `supabase/20261021_comunidades_base.sql` no SQL Editor.
3. Confirme que `user_settings`, `roles`, `voice_states`, `audit_log` e `reports` existem e estão com RLS ativo.
4. Publique `index.html` e aumente o identificador do cache em `sw.js`.
5. Teste login, configurações, chat, respostas, voz, câmera e compartilhamento de tela.

Esta atualização é aditiva: clientes antigos ignoram os novos campos e continuam funcionando.

