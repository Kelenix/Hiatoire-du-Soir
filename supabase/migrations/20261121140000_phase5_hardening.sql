-- Phase 5 : durcissement après la revue de sécurité (docs/security.md, ADR-036).

-- Tentatives de création : bornent la dépense chez Anthropic, échecs compris (le quota, lui, ne compte
-- que les histoires réussies). Gardées 2 jours.
create table public.generation_attempts (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  request_id uuid not null,
  tries smallint not null default 1,
  created_at timestamptz not null default now(),
  finished_at timestamptz,
  unique (user_id, request_id)
);

alter table public.generation_attempts enable row level security;
-- Aucun accès direct : seules les fonctions ci-dessous l'écrivent.

-- Avant tout appel à Claude : demande déjà servie (renvoie l'histoire), une seule création en cours par
-- compte (BUSY), 40 tentatives par 24 h en Premium (30 histoires + échecs), 10 sinon (ABUSE_LIMIT).
create function public.start_generation(p_user_id uuid, p_request_id uuid) returns public.stories
language plpgsql security definer set search_path = '' as $$
declare
  v_story public.stories;
  v_limit integer := case when public.is_premium(p_user_id) then 40 else 10 end;
begin
  perform pg_advisory_xact_lock(hashtext(p_user_id::text));

  select s.* into v_story
  from public.generations g join public.stories s on s.id = g.story_id
  where g.user_id = p_user_id and g.request_id = p_request_id;
  if found then
    return v_story;
  end if;

  if exists (select 1 from public.generation_attempts
             where user_id = p_user_id and finished_at is null and created_at > now() - interval '2 minutes') then
    raise exception 'BUSY';
  end if;
  if (select coalesce(sum(tries), 0) from public.generation_attempts
      where user_id = p_user_id and created_at > now() - interval '24 hours') >= v_limit then
    raise exception 'ABUSE_LIMIT';
  end if;

  insert into public.generation_attempts (user_id, request_id) values (p_user_id, p_request_id)
  on conflict (user_id, request_id) do update
    set tries = public.generation_attempts.tries + 1, created_at = now(), finished_at = null;
  return null;
end
$$;

-- Fin de tentative ; sans dépense (refus avant l'appel à Claude), elle ne compte pas.
create function public.finish_generation(p_user_id uuid, p_request_id uuid, p_has_spent boolean) returns void
language sql security definer set search_path = '' as $$
  update public.generation_attempts
  set finished_at = now(), tries = tries - case when p_has_spent then 0 else 1 end
  where user_id = p_user_id and request_id = p_request_id;
$$;

revoke execute on function public.start_generation(uuid, uuid), public.finish_generation(uuid, uuid, boolean)
  from public, anon, authenticated;
grant execute on function public.start_generation(uuid, uuid), public.finish_generation(uuid, uuid, boolean)
  to service_role;

select cron.schedule(
  'purge-tentatives-creation',
  '41 3 * * *',
  $$delete from public.generation_attempts where created_at < now() - interval '2 days'$$
);

-- Favoris : verrou par famille, pour que deux ajouts simultanés ne dépassent pas la limite de 3.
create or replace function public.set_favorite(p_story_id uuid, p_value boolean) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := (select auth.uid());
begin
  perform pg_advisory_xact_lock(hashtext('favorites:' || v_user::text));
  perform 1 from public.stories where id = p_story_id and user_id = v_user and not is_hidden for update;
  if not found then
    raise exception 'INVALID_INPUT';
  end if;
  if p_value and not public.is_premium(v_user)
     and not exists (select 1 from public.stories where id = p_story_id and is_favorite)
     and (select count(*) from public.stories where user_id = v_user and is_favorite) >= 3 then
    raise exception 'FAVORITES_LIMIT';
  end if;
  update public.stories
  set is_favorite = p_value, favorited_at = case when p_value then coalesce(favorited_at, now()) end
  where id = p_story_id;
end
$$;

-- Nouvelles fonctions fermées par défaut : l'accès s'accorde explicitement, fonction par fonction.
-- (PUBLIC se retire au niveau global : la règle par schéma ne peut que s'y ajouter.)
alter default privileges for role postgres revoke execute on functions from public;
alter default privileges for role postgres in schema public
  revoke execute on functions from anon, authenticated;
