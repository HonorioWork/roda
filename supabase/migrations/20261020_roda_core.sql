-- Base segura do Roda. Migration aditiva: não altera nem remove tabelas de outros projetos.
begin;

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null check (char_length(username) between 1 and 40),
  tag_number integer not null check (tag_number between 0 and 9999),
  avatar_url text,
  status text not null default 'online' check (status in ('online','away','busy','invisible')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (username, tag_number)
);

create table if not exists public.servers (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 50),
  owner uuid not null references public.profiles(id) on delete restrict,
  invite_code text not null default lower(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10)) unique,
  icon_url text,
  is_public boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.members (
  server_id uuid not null references public.servers(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'member' check (role in ('admin','member')),
  joined_at timestamptz not null default now(),
  primary key (server_id, user_id)
);

create table if not exists public.channels (
  id uuid primary key default gen_random_uuid(),
  server_id uuid not null references public.servers(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 50),
  kind text not null default 'text' check (kind in ('text','voice')),
  position integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  channel_id uuid not null references public.channels(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  content text not null check (char_length(content) between 1 and 2000),
  edited boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.friendships (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id) on delete cascade,
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','accepted')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (sender_id <> recipient_id)
);
create unique index if not exists friendships_pair_unique
  on public.friendships (least(sender_id, recipient_id), greatest(sender_id, recipient_id));

create table if not exists public.direct_messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id) on delete cascade,
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  content text not null check (char_length(content) between 1 and 2000),
  created_at timestamptz not null default now(),
  check (sender_id <> recipient_id)
);

create table if not exists public.private_calls (
  id uuid primary key default gen_random_uuid(),
  caller_id uuid not null references public.profiles(id) on delete cascade,
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'ringing' check (status in ('ringing','accepted','declined','ended')),
  expires_at timestamptz not null default (now() + interval '65 seconds'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (caller_id <> recipient_id)
);

create table if not exists public.call_presence (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  channel_id uuid not null references public.channels(id) on delete cascade,
  updated_at timestamptz not null default now()
);

create index if not exists members_user_idx on public.members(user_id);
create index if not exists channels_server_position_idx on public.channels(server_id, position, created_at);
create index if not exists messages_channel_time_idx on public.messages(channel_id, created_at desc);
create index if not exists friendships_sender_idx on public.friendships(sender_id, created_at desc);
create index if not exists friendships_recipient_idx on public.friendships(recipient_id, created_at desc);
create index if not exists direct_messages_sender_time_idx on public.direct_messages(sender_id, created_at desc);
create index if not exists direct_messages_recipient_time_idx on public.direct_messages(recipient_id, created_at desc);
create index if not exists private_calls_recipient_time_idx on public.private_calls(recipient_id, created_at desc);
create index if not exists call_presence_channel_idx on public.call_presence(channel_id, updated_at desc);

create or replace function public.touch_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_touch_updated_at on public.profiles;
create trigger profiles_touch_updated_at before update on public.profiles
for each row execute function public.touch_updated_at();
drop trigger if exists servers_touch_updated_at on public.servers;
create trigger servers_touch_updated_at before update on public.servers
for each row execute function public.touch_updated_at();
drop trigger if exists channels_touch_updated_at on public.channels;
create trigger channels_touch_updated_at before update on public.channels
for each row execute function public.touch_updated_at();
drop trigger if exists friendships_touch_updated_at on public.friendships;
create trigger friendships_touch_updated_at before update on public.friendships
for each row execute function public.touch_updated_at();
drop trigger if exists private_calls_touch_updated_at on public.private_calls;
create trigger private_calls_touch_updated_at before update on public.private_calls
for each row execute function public.touch_updated_at();
drop trigger if exists call_presence_touch_updated_at on public.call_presence;
create trigger call_presence_touch_updated_at before update on public.call_presence
for each row execute function public.touch_updated_at();

create or replace function public.is_member(target_server uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.members
    where server_id = target_server and user_id = (select auth.uid())
  );
$$;

create or replace function public.is_admin(target_server uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.members
    where server_id = target_server and user_id = (select auth.uid()) and role = 'admin'
  );
$$;

create or replace function public.channel_server(target_channel uuid)
returns uuid language sql stable security definer set search_path = '' as $$
  select server_id from public.channels where id = target_channel;
$$;

create or replace function public.are_friends(first_user uuid, second_user uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.friendships
    where status = 'accepted'
      and ((sender_id = first_user and recipient_id = second_user)
        or (sender_id = second_user and recipient_id = first_user))
  );
$$;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  base_name text;
  candidate integer;
begin
  base_name := left(coalesce(nullif(trim(new.raw_user_meta_data ->> 'username'), ''), nullif(split_part(new.email, '@', 1), ''), 'usuario'), 40);
  for attempt in 1..100 loop
    candidate := floor(random() * 10000)::integer;
    begin
      insert into public.profiles (id, username, tag_number)
      values (new.id, base_name, candidate);
      return new;
    exception when unique_violation then
      null;
    end;
  end loop;
  raise exception 'Não foi possível gerar o identificador do perfil';
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.handle_new_server()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.members (server_id, user_id, role) values (new.id, new.owner, 'admin')
  on conflict (server_id, user_id) do update set role = 'admin';
  insert into public.channels (server_id, name, kind, position)
  values (new.id, 'geral', 'text', 0), (new.id, 'Voz', 'voice', 1);
  return new;
end;
$$;

drop trigger if exists on_server_created on public.servers;
create trigger on_server_created after insert on public.servers
for each row execute function public.handle_new_server();

create or replace function public.join_by_code(code text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  target uuid;
  normalized text;
begin
  normalized := lower(trim(code));
  select id into target from public.servers where lower(invite_code) = normalized;
  if target is null then raise exception 'Convite inválido'; end if;
  insert into public.members (server_id, user_id, role)
  values (target, (select auth.uid()), 'member')
  on conflict (server_id, user_id) do nothing;
  return target;
end;
$$;

revoke all on function public.touch_updated_at() from public, anon, authenticated;
revoke all on function public.handle_new_user() from public, anon, authenticated;
revoke all on function public.handle_new_server() from public, anon, authenticated;
revoke all on function public.is_member(uuid) from public, anon, authenticated;
revoke all on function public.is_admin(uuid) from public, anon, authenticated;
revoke all on function public.channel_server(uuid) from public, anon, authenticated;
revoke all on function public.are_friends(uuid,uuid) from public, anon, authenticated;
revoke all on function public.join_by_code(text) from public, anon, authenticated;
grant execute on function public.is_member(uuid), public.is_admin(uuid), public.channel_server(uuid), public.are_friends(uuid,uuid), public.join_by_code(text) to authenticated;

alter table public.profiles enable row level security;
alter table public.servers enable row level security;
alter table public.members enable row level security;
alter table public.channels enable row level security;
alter table public.messages enable row level security;
alter table public.friendships enable row level security;
alter table public.direct_messages enable row level security;
alter table public.private_calls enable row level security;
alter table public.call_presence enable row level security;

revoke all on public.profiles, public.servers, public.members, public.channels, public.messages,
  public.friendships, public.direct_messages, public.private_calls, public.call_presence from anon, authenticated;
grant select, update on public.profiles to authenticated;
grant select, insert, update, delete on public.servers, public.members, public.channels, public.messages,
  public.friendships, public.direct_messages, public.private_calls, public.call_presence to authenticated;

create policy profiles_read_authenticated on public.profiles for select to authenticated using (true);
create policy profiles_update_own on public.profiles for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));

create policy servers_read_visible on public.servers for select to authenticated
  using (is_public or owner = (select auth.uid()) or public.is_member(id));
create policy servers_create_own on public.servers for insert to authenticated
  with check (owner = (select auth.uid()));
create policy servers_update_owner on public.servers for update to authenticated
  using (owner = (select auth.uid())) with check (owner = (select auth.uid()));
create policy servers_delete_owner on public.servers for delete to authenticated
  using (owner = (select auth.uid()));

create policy members_read_members on public.members for select to authenticated
  using (public.is_member(server_id));
create policy members_insert_admin on public.members for insert to authenticated
  with check (public.is_admin(server_id));
create policy members_update_admin on public.members for update to authenticated
  using (public.is_admin(server_id)) with check (public.is_admin(server_id));
create policy members_delete_self_or_admin on public.members for delete to authenticated
  using (user_id = (select auth.uid()) or public.is_admin(server_id));

create policy channels_read_members on public.channels for select to authenticated
  using (public.is_member(server_id));
create policy channels_manage_admins on public.channels for all to authenticated
  using (public.is_admin(server_id)) with check (public.is_admin(server_id));

create policy messages_read_members on public.messages for select to authenticated
  using (public.is_member(public.channel_server(channel_id)));
create policy messages_insert_own on public.messages for insert to authenticated
  with check (user_id = (select auth.uid()) and public.is_member(public.channel_server(channel_id)));
create policy messages_update_own on public.messages for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy messages_delete_own_or_admin on public.messages for delete to authenticated
  using (user_id = (select auth.uid()) or public.is_admin(public.channel_server(channel_id)));

create policy friendships_read_participants on public.friendships for select to authenticated
  using ((select auth.uid()) in (sender_id, recipient_id));
create policy friendships_create_sender on public.friendships for insert to authenticated
  with check (sender_id = (select auth.uid()) and status = 'pending');
create policy friendships_accept_recipient on public.friendships for update to authenticated
  using (recipient_id = (select auth.uid()))
  with check (recipient_id = (select auth.uid()) and status = 'accepted');
create policy friendships_delete_participants on public.friendships for delete to authenticated
  using ((select auth.uid()) in (sender_id, recipient_id));

create policy direct_messages_read_participants on public.direct_messages for select to authenticated
  using ((select auth.uid()) in (sender_id, recipient_id));
create policy direct_messages_send_friends on public.direct_messages for insert to authenticated
  with check (sender_id = (select auth.uid()) and public.are_friends(sender_id, recipient_id));

create policy private_calls_read_participants on public.private_calls for select to authenticated
  using ((select auth.uid()) in (caller_id, recipient_id));
create policy private_calls_create_caller on public.private_calls for insert to authenticated
  with check (caller_id = (select auth.uid()) and status = 'ringing' and public.are_friends(caller_id, recipient_id));
create policy private_calls_update_participants on public.private_calls for update to authenticated
  using ((select auth.uid()) in (caller_id, recipient_id))
  with check ((select auth.uid()) in (caller_id, recipient_id));
create policy private_calls_delete_participants on public.private_calls for delete to authenticated
  using ((select auth.uid()) in (caller_id, recipient_id));

create policy call_presence_read_members on public.call_presence for select to authenticated
  using (public.is_member(public.channel_server(channel_id)));
create policy call_presence_write_own on public.call_presence for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()) and public.is_member(public.channel_server(channel_id)));

do $$
declare table_name text;
begin
  foreach table_name in array array['messages','direct_messages','private_calls','call_presence'] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = table_name
    ) then
      execute format('alter publication supabase_realtime add table public.%I', table_name);
    end if;
  end loop;
end $$;

notify pgrst, 'reload schema';
commit;

