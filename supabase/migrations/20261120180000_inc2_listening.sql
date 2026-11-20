-- Inc-2 : une écoute par histoire en gratuit (US-11, H5). Les écoutes illimitées Premium arrivent à l'Inc-5.

alter table public.stories add column listens_count integer not null default 0 check (listens_count >= 0);

-- Décompte une écoute au démarrage, ou refuse (LOCKED) si l'histoire a déjà été écoutée.
create function public.start_listening(p_story_id uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
  update public.stories
  set listens_count = listens_count + 1
  where id = p_story_id and user_id = (select auth.uid()) and listens_count < 1;
  if found then
    return;
  end if;
  if exists (select 1 from public.stories where id = p_story_id and user_id = (select auth.uid())) then
    raise exception 'LOCKED';
  end if;
  raise exception 'INVALID_INPUT';
end
$$;

revoke execute on function public.start_listening(uuid) from public, anon;
grant execute on function public.start_listening(uuid) to authenticated;
