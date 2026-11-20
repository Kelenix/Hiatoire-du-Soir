-- Inc-1 : catalogue des thèmes, histoires, journal des générations et quota gratuit.
-- Modèle : docs/data-model.md · Flux : docs/system-design.md §2.2

create type public.theme_tier as enum ('free', 'premium', 'seasonal');
create type public.generation_source as enum ('premium', 'free', 'credit');

create table public.themes (
  id text primary key check (id ~ '^[a-z0-9-]{2,40}$'),
  name text not null,
  tier public.theme_tier not null,
  writing_guide text not null,
  illustration text not null,
  sort_order smallint not null default 0,
  is_active boolean not null default true
);

create table public.stories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  theme_id text not null references public.themes (id),
  duration_min smallint not null check (duration_min in (2, 5, 10)),
  title text not null check (char_length(title) between 1 and 120),
  paragraphs text[] not null check (cardinality(paragraphs) between 1 and 80),
  created_at timestamptz not null default now()
);

create index stories_user_created_idx on public.stories (user_id, created_at desc);

-- Journal sans texte : quota, anti-abus et suivi des coûts (ADR-018).
create table public.generations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  request_id uuid not null,
  source public.generation_source not null,
  theme_id text not null references public.themes (id),
  duration_min smallint not null,
  story_id uuid references public.stories (id) on delete set null,
  input_tokens integer not null default 0,
  output_tokens integer not null default 0,
  created_at timestamptz not null default now(),
  unique (user_id, request_id)
);

create index generations_user_created_idx on public.generations (user_id, created_at);

-- Accès : RLS sur toutes les tables ; écritures uniquement par les fonctions ci-dessous.
alter table public.themes enable row level security;
alter table public.stories enable row level security;
alter table public.generations enable row level security;

create policy "Thèmes actifs lisibles par les utilisateurs connectés" on public.themes
  for select to authenticated using (is_active);

create policy "Chacun lit ses propres histoires" on public.stories
  for select to authenticated using (user_id = (select auth.uid()));

-- Lundi 00:00, heure de Paris (H4).
create function public.week_start() returns timestamptz
language sql stable set search_path = '' as $$
  select date_trunc('week', now() at time zone 'Europe/Paris') at time zone 'Europe/Paris'
$$;

create function public.free_stories_left(p_user_id uuid) returns integer
language sql stable security definer set search_path = '' as $$
  select greatest(0, 3 - count(*)::integer)
  from public.generations
  where user_id = p_user_id and source = 'free' and created_at >= public.week_start()
$$;

create function public.my_entitlements() returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object('free_stories_left', public.free_stories_left((select auth.uid())))
$$;

-- Source d'une création, ou refus (codes lus par generate-story). Premium et crédits : Inc-5 et Inc-7.
create function public.precheck_generation(p_user_id uuid, p_theme_id text, p_duration_min smallint)
returns public.generation_source
language plpgsql stable security definer set search_path = '' as $$
declare
  v_tier public.theme_tier;
begin
  select tier into v_tier from public.themes where id = p_theme_id and is_active;
  if not found then
    raise exception 'INVALID_INPUT';
  end if;
  if v_tier <> 'free' or p_duration_min <> 2 then
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
  p_output_tokens integer
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

  v_source := public.precheck_generation(p_user_id, p_theme_id, p_duration_min);

  insert into public.stories (user_id, theme_id, duration_min, title, paragraphs)
  values (p_user_id, p_theme_id, p_duration_min, p_title, p_paragraphs)
  returning * into v_story;

  insert into public.generations
    (user_id, request_id, source, theme_id, duration_min, story_id, input_tokens, output_tokens)
  values
    (p_user_id, p_request_id, v_source, p_theme_id, p_duration_min, v_story.id, p_input_tokens, p_output_tokens);

  -- H13 : seule la dernière histoire est gardée (les favoris s'y ajouteront à l'Inc-3).
  delete from public.stories where user_id = p_user_id and id <> v_story.id;

  return v_story;
end
$$;

revoke execute on function
  public.week_start(),
  public.free_stories_left(uuid),
  public.my_entitlements(),
  public.precheck_generation(uuid, text, smallint),
  public.commit_generation(uuid, uuid, text, smallint, text, text[], integer, integer)
from public, anon, authenticated;

grant execute on function public.my_entitlements() to authenticated;
grant execute on function
  public.precheck_generation(uuid, text, smallint),
  public.commit_generation(uuid, uuid, text, smallint, text, text[], integer, integer)
to service_role;

-- Catalogue de départ (H6). Illustrations manquantes : château provisoire (charte §8).
insert into public.themes (id, name, tier, writing_guide, illustration, sort_order) values
  ('animaux', 'Animaux', 'free',
   'Des animaux attachants (renardeau, lapin, ourson, chouette) vivent une petite aventure pleine de tendresse dans la nature.',
   'mascot', 1),
  ('foret-magique', 'Forêt magique', 'free',
   'Une forêt enchantée la nuit : arbres qui murmurent, lucioles, champignons lumineux, ruisseau qui chante.',
   'forest', 2),
  ('ocean', 'Océan', 'premium',
   'Sous la mer, entre coraux colorés, poissons-lune et baleines bienveillantes.',
   'castle', 3),
  ('espace', 'Espace', 'premium',
   'Un voyage tout doux parmi les étoiles, les planètes et une lune qui sourit.',
   'castle', 4),
  ('dinosaures', 'Dinosaures', 'premium',
   'Des dinosaures gentils et rigolos dans une vallée préhistorique ensoleillée.',
   'castle', 5),
  ('chevaliers-dragons', 'Chevaliers et dragons', 'premium',
   'Un royaume de contes où chevaliers et dragons deviennent les meilleurs amis du monde.',
   'dragon', 6),
  ('pirates', 'Pirates', 'premium',
   'Une chasse au trésor joyeuse à bord du bateau de pirates très sympathiques.',
   'castle', 7),
  ('noel', 'Noël', 'seasonal',
   'La magie de Noël : neige, lutins, maison chaleureuse et Père Noël bienveillant.',
   'christmas', 8),
  ('halloween', 'Halloween', 'seasonal',
   'Un Halloween tout doux et jamais effrayant : citrouilles souriantes, fantômes timides, bonbons partagés.',
   'castle', 9);
