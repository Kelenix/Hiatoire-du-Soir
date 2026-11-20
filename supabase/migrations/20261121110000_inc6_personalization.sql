-- Inc-6 : personnages et histoires sur mesure (US-30 à US-32, H14, H15, ADR-004, ADR-017).

create type public.hero_gender as enum ('girl', 'boy', 'neutral');

-- Listes fermées, partagées avec l'app (lib/features/characters/domain/character.dart) et generate-story.
create table public.characters (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users (id) on delete cascade,
  theme_id text references public.themes (id),
  name text not null check (char_length(trim(name)) between 1 and 20),
  gender public.hero_gender not null,
  animal text not null check (animal in
    ('renard', 'lapin', 'ours', 'chat', 'chien', 'chouette', 'dragon', 'licorne', 'dauphin', 'tortue')),
  trait text not null check (trait in ('courageux', 'curieux', 'rigolo', 'doux', 'malin', 'reveur')),
  created_at timestamptz not null default now(),
  -- Personnage prêt à l'emploi (aucun propriétaire) ou personnage de la famille (sans thème).
  check ((user_id is null) <> (theme_id is null))
);

create index characters_user_idx on public.characters (user_id);

create table public.situations (
  id text primary key check (id ~ '^[a-z0-9-]{2,40}$'),
  label text not null,
  writing_guide text not null,
  sort_order smallint not null default 0,
  is_active boolean not null default true
);

alter table public.characters enable row level security;
alter table public.situations enable row level security;

create policy "Personnages prêts et personnages de la famille" on public.characters
  for select to authenticated using (user_id is null or user_id = (select auth.uid()));
create policy "Le parent crée ses personnages" on public.characters
  for insert to authenticated
  with check (user_id = (select auth.uid()) and theme_id is null);
create policy "Le parent modifie ses personnages" on public.characters
  for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()) and theme_id is null);
create policy "Le parent supprime ses personnages" on public.characters
  for delete to authenticated using (user_id = (select auth.uid()));

create policy "Situations actives lisibles" on public.situations
  for select to authenticated using (is_active);

-- 10 personnages de la famille au plus : largement assez, et pas de stockage sans fin.
-- Compté dans un déclencheur : une sous-requête dans la policy relancerait la policy (récursion).
create function public.check_characters_limit() returns trigger
language plpgsql set search_path = '' as $$
begin
  perform pg_advisory_xact_lock(hashtext('characters:' || new.user_id::text));
  if (select count(*) from public.characters where user_id = new.user_id) >= 10 then
    raise exception 'CHARACTERS_LIMIT';
  end if;
  return new;
end
$$;

create trigger characters_limit before insert on public.characters
  for each row when (new.user_id is not null) execute function public.check_characters_limit();

-- Le prénom n'est jamais dans le texte (marqueur {{HEROS}}) : il est gardé à part (ADR-017).
alter table public.stories
  add column hero_name text check (char_length(hero_name) <= 20),
  add column hero_gender public.hero_gender;

-- Histoire personnalisée (personnage de la famille, animal, situation) : Premium, ou crédit à l'Inc-7.
-- Un personnage prêt à l'emploi reste accessible à tous (US-31).
drop function public.commit_generation(uuid, uuid, text, smallint, text, text[], integer, integer);
drop function public.precheck_generation(uuid, text, smallint);

create function public.precheck_generation(
  p_user_id uuid,
  p_theme_id text,
  p_duration_min smallint,
  p_personalized boolean default false
) returns public.generation_source
language plpgsql stable security definer set search_path = '' as $$
declare
  v_tier public.theme_tier;
begin
  select tier into v_tier from public.themes where id = p_theme_id and is_active;
  if not found then
    raise exception 'INVALID_INPUT';
  end if;
  if public.is_premium(p_user_id) then
    if (select count(*) from public.generations
        where user_id = p_user_id and source = 'premium' and created_at > now() - interval '24 hours') >= 30 then
      raise exception 'ABUSE_LIMIT';
    end if;
    return 'premium';
  end if;
  if v_tier <> 'free' or p_duration_min <> 2 or p_personalized then
    raise exception 'LOCKED';
  end if;
  if public.free_stories_left(p_user_id) = 0 then
    raise exception 'QUOTA_REACHED';
  end if;
  return 'free';
end
$$;

create function public.commit_generation(
  p_user_id uuid,
  p_request_id uuid,
  p_theme_id text,
  p_duration_min smallint,
  p_title text,
  p_paragraphs text[],
  p_input_tokens integer,
  p_output_tokens integer,
  p_hero_name text default null,
  p_hero_gender public.hero_gender default null,
  p_personalized boolean default false
) returns public.stories
language plpgsql security definer set search_path = '' as $$
declare
  v_story public.stories;
  v_source public.generation_source;
begin
  -- Une création à la fois par utilisateur : deux demandes simultanées ne dépassent jamais le quota.
  perform pg_advisory_xact_lock(hashtext(p_user_id::text));

  -- Demande rejouée (double appui, réponse perdue) : on renvoie l'histoire déjà créée, sans rien débiter.
  select s.* into v_story
  from public.generations g join public.stories s on s.id = g.story_id
  where g.user_id = p_user_id and g.request_id = p_request_id;
  if found then
    return v_story;
  end if;

  v_source := public.precheck_generation(p_user_id, p_theme_id, p_duration_min, p_personalized);

  insert into public.stories (user_id, theme_id, duration_min, title, paragraphs, hero_name, hero_gender)
  values (p_user_id, p_theme_id, p_duration_min, p_title, p_paragraphs, p_hero_name, p_hero_gender)
  returning * into v_story;

  insert into public.generations
    (user_id, request_id, source, theme_id, duration_min, story_id, input_tokens, output_tokens)
  values
    (p_user_id, p_request_id, v_source, p_theme_id, p_duration_min, v_story.id, p_input_tokens, p_output_tokens);

  delete from public.stories where user_id = p_user_id and id <> v_story.id and not is_favorite;

  return v_story;
end
$$;

revoke execute on function
  public.precheck_generation(uuid, text, smallint, boolean),
  public.commit_generation(uuid, uuid, text, smallint, text, text[], integer, integer, text, public.hero_gender, boolean)
from public, anon, authenticated;
grant execute on function
  public.precheck_generation(uuid, text, smallint, boolean),
  public.commit_generation(uuid, uuid, text, smallint, text, text[], integer, integer, text, public.hero_gender, boolean)
to service_role;

insert into public.characters (theme_id, name, gender, animal, trait) values
  ('animaux', 'Pipo', 'boy', 'renard', 'curieux'),
  ('foret-magique', 'Plume', 'girl', 'chouette', 'doux'),
  ('ocean', 'Bulle', 'girl', 'dauphin', 'rigolo'),
  ('chevaliers-dragons', 'Étincelle', 'boy', 'dragon', 'courageux');

insert into public.situations (id, label, writing_guide, sort_order) values
  ('premier-jour-ecole', 'Premier jour d’école',
   'Le héros vit son premier jour d’école : un peu d’appréhension, puis des rencontres rassurantes.', 1),
  ('peur-du-noir', 'Peur du noir',
   'Le héros a peur du noir et découvre que la nuit est douce et pleine d’amis bienveillants.', 2),
  ('nouveau-bebe', 'Un bébé arrive',
   'Un petit frère ou une petite sœur arrive : le héros trouve sa place de grand, avec tendresse.', 3),
  ('demenagement', 'Déménagement',
   'Le héros déménage : il dit au revoir à son ancienne maison et apprivoise la nouvelle.', 4),
  ('dentiste', 'Chez le dentiste',
   'Le héros va chez le dentiste et découvre que ce n’est ni douloureux ni effrayant.', 5),
  ('nuit-grands-parents', 'Une nuit chez papi et mamie',
   'Le héros dort pour la première fois chez ses grands-parents, entouré d’attentions.', 6);
