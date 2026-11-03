-- Corrige privilégios automáticos do projeto e cobre as FKs usadas pelo Roda.
begin;

revoke all on function public.touch_updated_at() from public, anon, authenticated;
revoke all on function public.handle_new_user() from public, anon, authenticated;
revoke all on function public.handle_new_server() from public, anon, authenticated;
revoke all on function public.is_member(uuid) from public, anon, authenticated;
revoke all on function public.is_admin(uuid) from public, anon, authenticated;
revoke all on function public.channel_server(uuid) from public, anon, authenticated;
revoke all on function public.are_friends(uuid,uuid) from public, anon, authenticated;
revoke all on function public.join_by_code(text) from public, anon, authenticated;
revoke all on function public.can_moderate_report(text,text) from public, anon, authenticated;

grant execute on function public.is_member(uuid), public.is_admin(uuid),
  public.channel_server(uuid), public.are_friends(uuid,uuid),
  public.join_by_code(text), public.can_moderate_report(text,text) to authenticated;

create index if not exists audit_log_actor_idx on public.audit_log(actor_id);
create index if not exists member_roles_role_idx on public.member_roles(role_id);
create index if not exists messages_user_idx on public.messages(user_id);
create index if not exists private_calls_caller_idx on public.private_calls(caller_id);
create index if not exists read_states_channel_idx on public.read_states(channel_id);
create index if not exists servers_owner_idx on public.servers(owner);
create index if not exists voice_states_user_idx on public.voice_states(user_id);

notify pgrst, 'reload schema';
commit;
