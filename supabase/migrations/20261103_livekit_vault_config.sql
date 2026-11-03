-- Leitura protegida das credenciais do LiveKit armazenadas no Supabase Vault.
-- Os valores são cadastrados diretamente no Vault e nunca entram no repositório.
create or replace function public.roda_voice_config()
returns table (lk_url text, lk_key text, lk_secret text)
language sql
security definer
set search_path = ''
as $$
  select
    max(decrypted_secret) filter (where name = 'roda_livekit_url') as lk_url,
    max(decrypted_secret) filter (where name = 'roda_livekit_key') as lk_key,
    max(decrypted_secret) filter (where name = 'roda_livekit_secret') as lk_secret
  from vault.decrypted_secrets
  where name in ('roda_livekit_url', 'roda_livekit_key', 'roda_livekit_secret');
$$;

revoke all on function public.roda_voice_config() from public, anon, authenticated;
grant execute on function public.roda_voice_config() to service_role;

comment on function public.roda_voice_config() is
  'Retorna a configuração do LiveKit somente para a função de backend com service_role.';
