-- A13: detalhes públicos da presença de voz. Rollback: remover as quatro colunas e a tabela da publicação.
begin;
alter table public.call_presence add column if not exists muted boolean not null default false;
alter table public.call_presence add column if not exists deafened boolean not null default false;
alter table public.call_presence add column if not exists video_on boolean not null default false;
alter table public.call_presence add column if not exists screen_sharing boolean not null default false;
do $$ begin
  if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='call_presence') then
    alter publication supabase_realtime add table public.call_presence;
  end if;
end $$;
notify pgrst, 'reload schema';
commit;
