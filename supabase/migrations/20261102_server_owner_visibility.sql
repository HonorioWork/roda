-- O dono precisa enxergar o servidor no RETURNING antes do gatilho concluir a associação.
begin;
alter policy servers_read_visible on public.servers
  using (is_public or owner = (select auth.uid()) or public.is_member(id));
notify pgrst, 'reload schema';
commit;
