-- Expansão aditiva do Roda atual: perfis, preferências, chat e base de comunidades.
-- Esta migration não remove nem renomeia objetos existentes.
begin;

alter table public.profiles add column if not exists display_name text;
alter table public.profiles add column if not exists banner_url text;
alter table public.profiles add column if not exists bio text;
alter table public.profiles add column if not exists pronouns text;
alter table public.profiles add column if not exists accent_color text default '#5865f2';
alter table public.profiles add column if not exists custom_status text;
alter table public.profiles add column if not exists custom_status_expires_at timestamptz;
alter table public.profiles add column if not exists birth_date date;
alter table public.profiles add column if not exists age_verified boolean not null default false;
alter table public.profiles add column if not exists age_band text;
alter table public.profiles add column if not exists is_minor boolean not null default false;

alter table public.members add column if not exists nickname text;
alter table public.members add column if not exists timeout_until timestamptz;

alter table public.channels add column if not exists topic text;
alter table public.channels add column if not exists nsfw boolean not null default false;
alter table public.channels add column if not exists slowmode_seconds integer not null default 0;
alter table public.channels add column if not exists user_limit integer not null default 0;
alter table public.channels add column if not exists bitrate integer not null default 64000;

alter table public.messages add column if not exists reply_to uuid references public.messages(id) on delete set null;
alter table public.messages add column if not exists edited_at timestamptz;
alter table public.messages add column if not exists pinned boolean not null default false;
create index if not exists messages_reply_to_idx on public.messages(reply_to);

create table if not exists public.user_settings (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  version integer not null default 1,
  settings jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
alter table public.user_settings enable row level security;
revoke all on public.user_settings from anon, authenticated;
grant select, insert, update on public.user_settings to authenticated;
drop policy if exists user_settings_read_own on public.user_settings;
create policy user_settings_read_own on public.user_settings for select to authenticated
  using (user_id = (select auth.uid()));
drop policy if exists user_settings_insert_own on public.user_settings;
create policy user_settings_insert_own on public.user_settings for insert to authenticated
  with check (user_id = (select auth.uid()));
drop policy if exists user_settings_update_own on public.user_settings;
create policy user_settings_update_own on public.user_settings for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  server_id uuid not null references public.servers(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 50),
  position integer not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists categories_server_position_idx on public.categories(server_id, position);
alter table public.categories enable row level security;
revoke all on public.categories from anon, authenticated;
grant select, insert, update, delete on public.categories to authenticated;
drop policy if exists categories_read_members on public.categories;
create policy categories_read_members on public.categories for select to authenticated using (public.is_member(server_id));
drop policy if exists categories_manage_admins on public.categories;
create policy categories_manage_admins on public.categories for all to authenticated using (public.is_admin(server_id)) with check (public.is_admin(server_id));

create table if not exists public.roles (
  id uuid primary key default gen_random_uuid(),
  server_id uuid not null references public.servers(id) on delete cascade,
  name text not null,
  permissions bigint not null default 0,
  position integer not null default 0,
  color text,
  icon_url text,
  hoist boolean not null default false,
  mentionable boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists roles_server_position_idx on public.roles(server_id, position desc);
alter table public.roles enable row level security;
revoke all on public.roles from anon, authenticated;
grant select, insert, update, delete on public.roles to authenticated;
drop policy if exists roles_read_members on public.roles;
create policy roles_read_members on public.roles for select to authenticated using (public.is_member(server_id));
drop policy if exists roles_manage_admins on public.roles;
create policy roles_manage_admins on public.roles for all to authenticated using (public.is_admin(server_id)) with check (public.is_admin(server_id));

create table if not exists public.member_roles (
  server_id uuid not null references public.servers(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role_id uuid not null references public.roles(id) on delete cascade,
  primary key (user_id, role_id)
);
create index if not exists member_roles_server_idx on public.member_roles(server_id);
alter table public.member_roles enable row level security;
revoke all on public.member_roles from anon, authenticated;
grant select, insert, delete on public.member_roles to authenticated;
drop policy if exists member_roles_read_members on public.member_roles;
create policy member_roles_read_members on public.member_roles for select to authenticated using (public.is_member(server_id));
drop policy if exists member_roles_manage_admins on public.member_roles;
create policy member_roles_manage_admins on public.member_roles for all to authenticated using (public.is_admin(server_id)) with check (public.is_admin(server_id));

create table if not exists public.channel_overwrites (
  channel_id uuid not null references public.channels(id) on delete cascade,
  target_type text not null check (target_type in ('role','member')),
  target_id uuid not null,
  allow bigint not null default 0,
  deny bigint not null default 0,
  primary key (channel_id, target_type, target_id)
);
alter table public.channel_overwrites enable row level security;
revoke all on public.channel_overwrites from anon, authenticated;
grant select, insert, update, delete on public.channel_overwrites to authenticated;
drop policy if exists overwrites_read_members on public.channel_overwrites;
create policy overwrites_read_members on public.channel_overwrites for select to authenticated using (public.is_member(public.channel_server(channel_id)));
drop policy if exists overwrites_manage_admins on public.channel_overwrites;
create policy overwrites_manage_admins on public.channel_overwrites for all to authenticated using (public.is_admin(public.channel_server(channel_id))) with check (public.is_admin(public.channel_server(channel_id)));

create table if not exists public.voice_states (
  channel_id uuid not null references public.channels(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  muted boolean not null default false,
  deafened boolean not null default false,
  video_on boolean not null default false,
  screen_sharing boolean not null default false,
  joined_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (channel_id, user_id)
);
alter table public.voice_states enable row level security;
revoke all on public.voice_states from anon, authenticated;
grant select, insert, update, delete on public.voice_states to authenticated;
drop policy if exists voice_states_read_members on public.voice_states;
create policy voice_states_read_members on public.voice_states for select to authenticated using (public.is_member(public.channel_server(channel_id)));
drop policy if exists voice_states_write_own on public.voice_states;
create policy voice_states_write_own on public.voice_states for all to authenticated using (user_id=(select auth.uid())) with check (user_id=(select auth.uid()) and public.is_member(public.channel_server(channel_id)));

create table if not exists public.audit_log (
  id bigint generated by default as identity primary key,
  server_id uuid not null references public.servers(id) on delete cascade,
  actor_id uuid references public.profiles(id) on delete set null,
  action text not null,
  target_type text,
  target_id text,
  changes jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists audit_log_server_time_idx on public.audit_log(server_id, created_at desc);
alter table public.audit_log enable row level security;
revoke all on public.audit_log from anon, authenticated;
grant select, insert on public.audit_log to authenticated;
drop policy if exists audit_read_admins on public.audit_log;
create policy audit_read_admins on public.audit_log for select to authenticated using (public.is_admin(server_id));
drop policy if exists audit_insert_actor on public.audit_log;
create policy audit_insert_actor on public.audit_log for insert to authenticated with check (actor_id=(select auth.uid()) and public.is_admin(server_id));

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  target_type text not null check (target_type in ('message','user','server','voice')),
  target_id text not null,
  reason text not null check (char_length(reason) between 3 and 1000),
  status text not null default 'open' check (status in ('open','reviewing','closed')),
  created_at timestamptz not null default now()
);
create index if not exists reports_reporter_time_idx on public.reports(reporter_id, created_at desc);
alter table public.reports enable row level security;
revoke all on public.reports from anon, authenticated;
grant select, insert on public.reports to authenticated;
drop policy if exists reports_create_own on public.reports;
create policy reports_create_own on public.reports for insert to authenticated with check (reporter_id=(select auth.uid()));
drop policy if exists reports_read_own on public.reports;
create policy reports_read_own on public.reports for select to authenticated using (reporter_id=(select auth.uid()));

grant update on public.messages to authenticated;
drop policy if exists messages_admin_update on public.messages;
create policy messages_admin_update on public.messages for update to authenticated
  using (public.is_admin(public.channel_server(channel_id)))
  with check (public.is_admin(public.channel_server(channel_id)));

notify pgrst, 'reload schema';
commit;
