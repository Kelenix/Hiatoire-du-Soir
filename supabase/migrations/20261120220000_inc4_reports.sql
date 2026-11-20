-- Inc-4 : signalement d'une histoire (US-22, H11), conservé 90 jours sans données personnelles.

create type public.report_reason as enum ('scary', 'violent', 'inappropriate', 'quality', 'other');

alter table public.stories add column is_hidden boolean not null default false;

drop policy "Chacun lit ses propres histoires" on public.stories;
create policy "Chacun lit ses propres histoires non signalées" on public.stories
  for select to authenticated using (user_id = (select auth.uid()) and not is_hidden);

-- Copie de l'histoire, sans utilisateur ni prénom : analyse des signalements.
create table public.story_reports (
  id uuid primary key default gen_random_uuid(),
  theme_id text not null references public.themes (id),
  title text not null,
  paragraphs text[] not null,
  reason public.report_reason not null,
  comment text check (char_length(comment) <= 500),
  created_at timestamptz not null default now()
);

alter table public.story_reports enable row level security;

create function public.report_story(p_story_id uuid, p_reason public.report_reason, p_comment text) returns void
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.story_reports (theme_id, title, paragraphs, reason, comment)
  select theme_id, title, paragraphs, p_reason, nullif(trim(p_comment), '')
  from public.stories
  where id = p_story_id and user_id = (select auth.uid()) and not is_hidden;
  if not found then
    raise exception 'INVALID_INPUT';
  end if;
  update public.stories set is_hidden = true, is_favorite = false, favorited_at = null where id = p_story_id;
end
$$;

revoke execute on function public.report_story(uuid, public.report_reason, text) from public, anon;
grant execute on function public.report_story(uuid, public.report_reason, text) to authenticated;

-- Une histoire signalée ne peut plus revenir en favori.
create or replace function public.set_favorite(p_story_id uuid, p_value boolean) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := (select auth.uid());
begin
  perform 1 from public.stories where id = p_story_id and user_id = v_user and not is_hidden for update;
  if not found then
    raise exception 'INVALID_INPUT';
  end if;
  if p_value and not exists (select 1 from public.stories where id = p_story_id and is_favorite)
     and (select count(*) from public.stories where user_id = v_user and is_favorite) >= 3 then
    raise exception 'FAVORITES_LIMIT';
  end if;
  update public.stories
  set is_favorite = p_value, favorited_at = case when p_value then coalesce(favorited_at, now()) end
  where id = p_story_id;
end
$$;

-- Purge quotidienne des signalements de plus de 90 jours (docs/data-model.md §7).
create extension if not exists pg_cron;
select cron.schedule(
  'purge-signalements',
  '17 3 * * *',
  $$delete from public.story_reports where created_at < now() - interval '90 days'$$
);
