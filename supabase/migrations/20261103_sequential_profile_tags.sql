-- Identificadores de perfil sequenciais: #0000, #0001, #0002...
-- O lock transacional impede números repetidos em cadastros simultâneos.
-- Rollback: remover profiles_tag_number_unique_idx e restaurar a geração aleatória
-- em public.handle_new_user(). Os números já atribuídos podem ser mantidos.
begin;

-- A conta invisível criada nos testes fica fora do começo da sequência.
update public.profiles
set tag_number = 9999
where id = (
  select p.id
  from public.profiles p
  where p.status = 'invisible'
  order by p.created_at
  limit 1
)
and not exists (
  select 1 from public.profiles occupied where occupied.tag_number = 9999
);

-- A conta real mais recente começa em #0000.
update public.profiles
set tag_number = 0
where id = (
  select p.id
  from public.profiles p
  join auth.users u on u.id = p.id
  where p.status <> 'invisible'
  order by u.last_sign_in_at desc nulls last, p.created_at desc
  limit 1
)
and not exists (
  select 1 from public.profiles occupied where occupied.tag_number = 0
);

create unique index if not exists profiles_tag_number_unique_idx
  on public.profiles(tag_number);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  base_name text;
  candidate integer;
begin
  base_name := left(
    coalesce(
      nullif(trim(new.raw_user_meta_data ->> 'username'), ''),
      nullif(split_part(new.email, '@', 1), ''),
      'usuario'
    ),
    40
  );

  perform pg_advisory_xact_lock(20261103, 1);

  select available.value
  into candidate
  from generate_series(0, 9999) as available(value)
  where not exists (
    select 1
    from public.profiles p
    where p.tag_number = available.value
  )
  order by available.value
  limit 1;

  if candidate is null then
    raise exception 'Todos os identificadores de perfil estão em uso';
  end if;

  insert into public.profiles (id, username, tag_number)
  values (new.id, base_name, candidate);

  return new;
end;
$$;

revoke all on function public.handle_new_user() from public, anon, authenticated;

commit;
