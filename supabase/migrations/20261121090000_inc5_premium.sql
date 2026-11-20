-- Inc-5 : abonnement Premium (US-24 à US-29, ADR-009, ADR-011, H19).

-- Droits écrits uniquement par le webhook d'achats (RevenueCat).
create table public.entitlements (
  user_id uuid primary key references auth.users (id) on delete cascade,
  premium_until timestamptz,
  has_voice_pack boolean not null default false,
  updated_at timestamptz not null default now()
);

-- Idempotence du webhook, sans détail de paiement.
create table public.purchase_events (
  event_id text primary key,
  user_id uuid references auth.users (id) on delete set null,
  type text not null,
  product_id text,
  occurred_at timestamptz not null
);

alter table public.entitlements enable row level security;
alter table public.purchase_events enable row level security;

create function public.is_premium(p_user_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.entitlements where user_id = p_user_id and premium_until > now())
$$;

create or replace function public.my_entitlements() returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'free_stories_left', public.free_stories_left(u.id),
    'is_premium', public.is_premium(u.id),
    'premium_until', (select premium_until from public.entitlements where user_id = u.id),
    'is_anonymous', u.is_anonymous
  )
  from auth.users u
  where u.id = (select auth.uid())
$$;

-- Premium : tous les thèmes et toutes les durées, 30 histoires par 24 h au plus (H19).
create or replace function public.precheck_generation(p_user_id uuid, p_theme_id text, p_duration_min smallint)
returns public.generation_source
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
  if v_tier <> 'free' or p_duration_min <> 2 then
    raise exception 'LOCKED';
  end if;
  if public.free_stories_left(p_user_id) = 0 then
    raise exception 'QUOTA_REACHED';
  end if;
  return 'free';
end
$$;

-- Premium : écoutes illimitées.
create or replace function public.start_listening(p_story_id uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := (select auth.uid());
begin
  update public.stories
  set listens_count = listens_count + 1
  where id = p_story_id and user_id = v_user and not is_hidden
    and (listens_count < 1 or public.is_premium(v_user));
  if found then
    return;
  end if;
  if exists (select 1 from public.stories where id = p_story_id and user_id = v_user and not is_hidden) then
    raise exception 'LOCKED';
  end if;
  raise exception 'INVALID_INPUT';
end
$$;

-- Premium : favoris illimités ; à l'expiration, les favoris restent mais l'ajout est bloqué au-delà de 3 (H10).
create or replace function public.set_favorite(p_story_id uuid, p_value boolean) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := (select auth.uid());
begin
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

-- Événement RevenueCat (docs/system-design.md §2.5) : idempotent, l'acheteur est l'utilisateur Supabase
-- (l'app se connecte à RevenueCat avec son identifiant). Droit RevenueCat attendu : « premium ».
create function public.apply_purchase_event(p_event jsonb) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid;
  v_type text := p_event ->> 'type';
  v_is_premium boolean := coalesce(p_event -> 'entitlement_ids' ? 'premium', false);
  v_expires timestamptz := to_timestamp((p_event ->> 'expiration_at_ms')::bigint / 1000.0);
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
  if not found or v_user is null or not v_is_premium then
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

revoke execute on function public.is_premium(uuid), public.apply_purchase_event(jsonb) from public, anon, authenticated;
grant execute on function public.apply_purchase_event(jsonb) to service_role;

-- Purge des événements d'achat après 13 mois (docs/data-model.md §7).
select cron.schedule(
  'purge-evenements-achat',
  '27 3 * * *',
  $$delete from public.purchase_events where occurred_at < now() - interval '13 months'$$
);
