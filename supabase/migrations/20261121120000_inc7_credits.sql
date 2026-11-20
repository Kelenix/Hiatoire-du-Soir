-- Inc-7 : packs d'histoires et crédits (US-33 à US-35, H8, H16, H20, ADR-011).

create type public.credit_scope as enum ('generic', 'premium_themes', 'noel', 'custom');

-- Packs vendus par les stores (consommables) : le contenu est ici, le prix vient du store.
create table public.credit_packs (
  product_id text primary key check (product_id ~ '^[a-z0-9_.]{3,100}$'),
  scope public.credit_scope not null,
  credits smallint not null check (credits > 0),
  name text not null,
  description text not null,
  sort_order smallint not null default 0,
  is_active boolean not null default true
);

-- Registre : le solde d'une portée est la somme de ses mouvements. Les crédits n'expirent pas (H20).
create table public.credit_ledger (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  scope public.credit_scope not null,
  delta integer not null check (delta <> 0),
  reason text not null check (reason in ('purchase', 'refund', 'generation')),
  purchase_event_id text references public.purchase_events (event_id) on delete set null,
  generation_id uuid references public.generations (id) on delete set null,
  created_at timestamptz not null default now()
);

create index credit_ledger_user_scope_idx on public.credit_ledger (user_id, scope);

alter table public.credit_packs enable row level security;
alter table public.credit_ledger enable row level security;

create policy "Packs actifs lisibles" on public.credit_packs
  for select to authenticated using (is_active);
-- credit_ledger : aucun accès direct ; soldes lus par my_entitlements, écritures par les fonctions.

create function public.credit_balance(p_user_id uuid, p_scope public.credit_scope) returns integer
language sql stable security definer set search_path = '' as $$
  select coalesce(sum(delta), 0)::integer from public.credit_ledger where user_id = p_user_id and scope = p_scope
$$;

-- Crédit à consommer pour une histoire, dans l'ordre H8 / H16 ; nul si aucun ne convient.
create function public.usable_credit_scope(p_user_id uuid, p_theme_id text, p_personalized boolean)
returns public.credit_scope
language sql stable security definer set search_path = '' as $$
  select rules.scope
  from (values
    (1, 'noel'::public.credit_scope, p_theme_id = 'noel'),
    (2, 'premium_themes'::public.credit_scope,
       not p_personalized and (select tier from public.themes where id = p_theme_id) = 'premium'),
    (3, 'custom'::public.credit_scope, p_personalized),
    (4, 'generic'::public.credit_scope, true)
  ) as rules (rank, scope, applies)
  where rules.applies and public.credit_balance(p_user_id, rules.scope) > 0
  order by rules.rank
  limit 1
$$;

-- Source d'une création : Premium → quota gratuit → crédits (US-35).
create or replace function public.precheck_generation(
  p_user_id uuid,
  p_theme_id text,
  p_duration_min smallint,
  p_personalized boolean default false
) returns public.generation_source
language plpgsql stable security definer set search_path = '' as $$
declare
  v_tier public.theme_tier;
  v_fits_free_offer boolean;
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
  v_fits_free_offer := v_tier = 'free' and p_duration_min = 2 and not p_personalized;
  if v_fits_free_offer and public.free_stories_left(p_user_id) > 0 then
    return 'free';
  end if;
  if public.usable_credit_scope(p_user_id, p_theme_id, p_personalized) is not null then
    return 'credit';
  end if;
  if v_fits_free_offer then
    raise exception 'QUOTA_REACHED';
  end if;
  raise exception 'LOCKED';
end
$$;

-- Un crédit n'est décompté que si l'histoire est bien créée (US-35).
create or replace function public.commit_generation(
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
  v_generation_id uuid;
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
    (p_user_id, p_request_id, v_source, p_theme_id, p_duration_min, v_story.id, p_input_tokens, p_output_tokens)
  returning id into v_generation_id;

  if v_source = 'credit' then
    insert into public.credit_ledger (user_id, scope, delta, reason, generation_id)
    values (p_user_id, public.usable_credit_scope(p_user_id, p_theme_id, p_personalized), -1, 'generation',
            v_generation_id);
  end if;

  delete from public.stories where user_id = p_user_id and id <> v_story.id and not is_favorite;

  return v_story;
end
$$;

-- Soldes positifs par portée ; l'app les montre aux parents seulement.
create or replace function public.my_entitlements() returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'free_stories_left', public.free_stories_left(u.id),
    'is_premium', public.is_premium(u.id),
    'premium_until', (select premium_until from public.entitlements where user_id = u.id),
    'is_anonymous', u.is_anonymous,
    'credits', coalesce((
      select jsonb_object_agg(balances.scope, balances.total)
      from (
        select scope, sum(delta) as total from public.credit_ledger
        where user_id = u.id group by scope having sum(delta) > 0
      ) balances
    ), '{}'::jsonb)
  )
  from auth.users u
  where u.id = (select auth.uid())
$$;

-- Événement RevenueCat : packs (achat unique, remboursement) puis abonnement Premium.
create or replace function public.apply_purchase_event(p_event jsonb) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid;
  v_type text := p_event ->> 'type';
  v_is_premium boolean := coalesce(p_event -> 'entitlement_ids' ? 'premium', false);
  v_expires timestamptz := to_timestamp((p_event ->> 'expiration_at_ms')::bigint / 1000.0);
  v_pack public.credit_packs;
begin
  select candidate::uuid into v_user
  from (
    select p_event ->> 'app_user_id' as candidate
    union all select p_event ->> 'original_app_user_id'
    union all select jsonb_array_elements_text(coalesce(p_event -> 'aliases', '[]'::jsonb))
  ) ids
  where candidate ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    and exists (select 1 from auth.users where id = candidate::uuid)
  limit 1;

  insert into public.purchase_events (event_id, user_id, type, product_id, occurred_at)
  values (p_event ->> 'id', v_user, v_type, p_event ->> 'product_id',
          to_timestamp((p_event ->> 'event_timestamp_ms')::bigint / 1000.0))
  on conflict (event_id) do nothing;
  if not found or v_user is null then
    return;
  end if;

  select * into v_pack from public.credit_packs where product_id = p_event ->> 'product_id';
  if found then
    -- Un remboursement retire les crédits du pack, même déjà utilisés (solde alors négatif).
    if v_type in ('NON_RENEWING_PURCHASE', 'CANCELLATION') then
      insert into public.credit_ledger (user_id, scope, delta, reason, purchase_event_id)
      values (v_user, v_pack.scope,
              case when v_type = 'CANCELLATION' then -v_pack.credits else v_pack.credits end,
              case when v_type = 'CANCELLATION' then 'refund' else 'purchase' end,
              p_event ->> 'id');
    end if;
    return;
  end if;
  if not v_is_premium then
    return;
  end if;

  if v_type in ('INITIAL_PURCHASE', 'RENEWAL', 'UNCANCELLATION', 'PRODUCT_CHANGE',
                'SUBSCRIPTION_EXTENDED', 'TEMPORARY_ENTITLEMENT_GRANT') then
    insert into public.entitlements (user_id, premium_until) values (v_user, v_expires)
    on conflict (user_id) do update
      set premium_until = greatest(public.entitlements.premium_until, excluded.premium_until), updated_at = now();
  elsif v_type = 'EXPIRATION' or (v_type = 'CANCELLATION' and p_event ->> 'cancel_reason' = 'CUSTOMER_SUPPORT') then
    update public.entitlements set premium_until = least(premium_until, now()), updated_at = now()
    where user_id = v_user;
  end if;
end
$$;

revoke execute on function
  public.credit_balance(uuid, public.credit_scope),
  public.usable_credit_scope(uuid, text, boolean)
from public, anon, authenticated;

-- Contenu des packs (H16). Identifiants à créer à l'identique dans Google Play et App Store.
insert into public.credit_packs (product_id, scope, credits, name, description, sort_order) values
  ('pack_aventures_10', 'premium_themes', 10, 'Aventures Premium',
   '10 histoires dans les univers Premium : Océan, Espace, Dinosaures, Chevaliers et dragons, Pirates.', 1),
  ('pack_noel_10', 'noel', 10, 'Pack Noël',
   '10 histoires de Noël, avec les personnages de votre famille.', 2),
  ('histoire_sur_mesure_1', 'custom', 1, 'Histoire sur mesure',
   '1 histoire avec le personnage de votre enfant, un animal et la situation de votre choix.', 3),
  ('pack_famille_30', 'generic', 30, 'Pack Famille',
   '30 histoires au choix : tous les thèmes, toutes les durées, personnages compris.', 4);
