-- Roda: anexos privados em canais e mensagens diretas.
-- Reversão: remover as políticas roda_message_files_*, o bucket message-files
-- e, depois de preservar os dados necessários, as quatro colunas attachment_* das duas tabelas.

begin;

alter table public.messages
  add column if not exists attachment_path text,
  add column if not exists attachment_name text,
  add column if not exists attachment_type text,
  add column if not exists attachment_size bigint;

alter table public.direct_messages
  add column if not exists attachment_path text,
  add column if not exists attachment_name text,
  add column if not exists attachment_type text,
  add column if not exists attachment_size bigint;

alter table public.messages
  drop constraint if exists messages_attachment_size_check;
alter table public.messages
  add constraint messages_attachment_size_check
  check (attachment_size is null or attachment_size between 0 and 20971520);

alter table public.direct_messages
  drop constraint if exists direct_messages_attachment_size_check;
alter table public.direct_messages
  add constraint direct_messages_attachment_size_check
  check (attachment_size is null or attachment_size between 0 and 20971520);

insert into storage.buckets (id, name, public, file_size_limit)
values ('message-files', 'message-files', false, 20971520)
on conflict (id) do update
set public = false, file_size_limit = excluded.file_size_limit;

drop policy if exists roda_message_files_insert_own on storage.objects;
create policy roda_message_files_insert_own
on storage.objects for insert to authenticated
with check (
  bucket_id = 'message-files'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

drop policy if exists roda_message_files_read_allowed on storage.objects;
create policy roda_message_files_read_allowed
on storage.objects for select to authenticated
using (
  bucket_id = 'message-files'
  and (
    (storage.foldername(name))[1] = (select auth.uid()::text)
    or exists (
      select 1
      from public.messages m
      where m.attachment_path = storage.objects.name
        and public.is_member(public.channel_server(m.channel_id))
    )
    or exists (
      select 1
      from public.direct_messages dm
      where dm.attachment_path = storage.objects.name
        and (select auth.uid()) in (dm.sender_id, dm.recipient_id)
    )
  )
);

drop policy if exists roda_message_files_delete_own on storage.objects;
create policy roda_message_files_delete_own
on storage.objects for delete to authenticated
using (
  bucket_id = 'message-files'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

notify pgrst, 'reload schema';
commit;
