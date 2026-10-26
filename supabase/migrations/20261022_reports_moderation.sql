begin;

create or replace function public.can_moderate_report(kind text, target text)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare target_uuid uuid;
begin
  if target !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' then
    return false;
  end if;
  target_uuid := target::uuid;
  if kind = 'server' then
    return public.is_admin(target_uuid);
  elsif kind = 'message' then
    return exists (
      select 1 from public.messages m
      join public.channels c on c.id = m.channel_id
      where m.id = target_uuid and public.is_admin(c.server_id)
    );
  elsif kind in ('user','voice') then
    return exists (
      select 1 from public.members reported
      join public.members moderator on moderator.server_id = reported.server_id
      where reported.user_id = target_uuid
        and moderator.user_id = (select auth.uid())
        and moderator.role = 'admin'
    );
  end if;
  return false;
end;
$$;

revoke all on function public.can_moderate_report(text,text) from public;
grant execute on function public.can_moderate_report(text,text) to authenticated;

do $$
begin
  if exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'reports' and policyname = 'reports_read_own'
  ) then
    alter policy reports_read_own on public.reports
      using (public.can_moderate_report(target_type,target_id));
  else
    create policy reports_read_own on public.reports for select to authenticated
      using (public.can_moderate_report(target_type,target_id));
  end if;
end $$;

notify pgrst, 'reload schema';
commit;

-- Rollback: alter policy reports_read_own on public.reports
-- using (reporter_id = (select auth.uid()));
