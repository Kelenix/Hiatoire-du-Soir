-- Inc-3 : favoris (US-13), 3 au maximum en gratuit (US-14, H10), histoires gardées (H13).

alter table public.stories
  add column is_favorite boolean not null default false,
  add column favorited_at timestamptz;

create index stories_user_favorites_idx on public.stories (user_id, favorited_at desc) where is_favorite;

-- Ajoute ou retire un favori. Au-delà de 3, refus (FAVORITES_LIMIT) ; illimité en Premium à l'Inc-5.
-- Les favoris déjà gardés restent lisibles même au-delà de 3 (H10).
create function public.set_favorite(p_story_id uuid, p_value boolean) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := (select auth.uid());
begin
  perform 1 from public.stories where id = p_story_id and user_id = v_user for update;
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

revoke execute on function public.set_favorite(uuid, boolean) from public, anon;
grant execute on function public.set_favorite(uuid, boolean) to authenticated;

-- H13 : on garde désormais les favoris en plus de la dernière histoire.
create or replace function public.commit_generation(
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

  delete from public.stories where user_id = p_user_id and id <> v_story.id and not is_favorite;

  return v_story;
end
$$;
