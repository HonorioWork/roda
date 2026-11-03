-- Corrige a leitura do identificador em gatilhos usados por tabelas diferentes.
-- Rollback: reaplicar a versão anterior de private.capture_account_snapshot().
begin;

create or replace function private.capture_account_snapshot()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_user uuid;
  captured_profile jsonb;
  captured_settings jsonb;
begin
  -- NEW é um record dinâmico: ler por JSON evita acessar um campo inexistente
  -- quando o gatilho vem de profiles (id) ou user_settings (user_id).
  target_user := nullif(
    coalesce(to_jsonb(new)->>'id', to_jsonb(new)->>'user_id'),
    ''
  )::uuid;

  if target_user is null then
    return new;
  end if;

  select jsonb_build_object(
    'username', p.username,
    'tag_number', p.tag_number,
    'avatar_url', p.avatar_url,
    'status', p.status,
    'display_name', p.display_name,
    'banner_url', p.banner_url,
    'bio', p.bio,
    'pronouns', p.pronouns,
    'accent_color', p.accent_color,
    'custom_status', p.custom_status,
    'updated_at', p.updated_at
  ) into captured_profile
  from public.profiles p
  where p.id = target_user;

  select jsonb_build_object(
    'version', s.version,
    'settings', s.settings,
    'updated_at', s.updated_at
  ) into captured_settings
  from public.user_settings s
  where s.user_id = target_user;

  insert into public.account_data_snapshots (
    user_id, snapshot_day, profile_data, settings_data, updated_at
  ) values (
    target_user,
    current_date,
    coalesce(captured_profile, '{}'::jsonb),
    coalesce(captured_settings, '{}'::jsonb),
    now()
  )
  on conflict (user_id, snapshot_day) do update
  set profile_data = excluded.profile_data,
      settings_data = excluded.settings_data,
      updated_at = excluded.updated_at;

  return new;
end;
$$;

revoke all on function private.capture_account_snapshot() from public, anon, authenticated;

commit;
