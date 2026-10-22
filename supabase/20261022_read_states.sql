-- A20: posição de leitura por canal. Rollback: drop table public.read_states;
begin;
create table if not exists public.read_states(
  user_id uuid not null references public.profiles(id) on delete cascade,
  channel_id uuid not null references public.channels(id) on delete cascade,
  last_read_at timestamptz not null default now(),
  primary key(user_id,channel_id)
);
alter table public.read_states enable row level security;
revoke all on public.read_states from anon,authenticated;
grant select,insert,update on public.read_states to authenticated;
do $$ begin
  if exists(select 1 from pg_policies where schemaname='public' and tablename='read_states' and policyname='read_states_own') then
    alter policy read_states_own on public.read_states using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()) and public.is_member(public.channel_server(channel_id)));
  else
    create policy read_states_own on public.read_states for all to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()) and public.is_member(public.channel_server(channel_id)));
  end if;
end $$;
notify pgrst, 'reload schema';
commit;
