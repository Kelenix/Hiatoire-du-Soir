-- Inc-8 : voix apaisantes Google et Pack Voix (US-36, US-37, ADR-008, H9).

-- Voix apaisantes du catalogue (la voix du téléphone n'y figure pas). L'audio gardé est rangé sous
-- l'identifiant de la voix : pour changer de voix Google, désactiver l'entrée et en créer une nouvelle.
create table public.voices (
  id text primary key check (id ~ '^[a-z0-9-]{2,40}$'),
  name text not null check (char_length(name) between 1 and 30),
  description text not null check (char_length(description) between 1 and 120),
  provider_voice text not null,
  speaking_rate numeric(3, 2) not null default 1 check (speaking_rate between 0.5 and 1.5),
  sort_order smallint not null default 0,
  is_active boolean not null default true
);

alter table public.voices enable row level security;

create policy "Voix actives lisibles" on public.voices
  for select to authenticated using (is_active);

insert into public.voices (id, name, description, provider_voice, speaking_rate, sort_order) values
  ('douce', 'Douce', 'Une voix de femme, tendre et posée.', 'fr-FR-Wavenet-F', 0.9, 1),
  ('conteur', 'Conteur', 'Une voix d’homme, calme et chaleureuse.', 'fr-FR-Wavenet-D', 0.88, 2),
  ('lune', 'Lune', 'Une voix de femme, légère comme un murmure.', 'fr-FR-Wavenet-C', 0.85, 3);

-- Audio des voix apaisantes : {famille}/{histoire}-{voix}.mp3 et extraits/{voix}.mp3. Écrit par
-- synthesize-voice (clé de service) ; chaque famille ne lit que son dossier et les extraits.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('story-audio', 'story-audio', false, 10485760, array['audio/mpeg']);

create policy "Audio de la famille et extraits lisibles" on storage.objects
  for select to authenticated
  using (bucket_id = 'story-audio'
         and (storage.foldername(name))[1] in ((select auth.uid())::text, 'extraits'));

create or replace function public.my_entitlements() returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'free_stories_left', public.free_stories_left(u.id),
    'is_premium', public.is_premium(u.id),
    'premium_until', e.premium_until,
    'has_voice_pack', coalesce(e.has_voice_pack, false),
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
  left join public.entitlements e on e.user_id = u.id
  where u.id = (select auth.uid())
$$;

-- Texte d'une histoire pour une voix apaisante, ou refus ; n'écrit rien : l'écoute est décomptée par
-- start_listening quand l'app lance la lecture. Pack Voix sans Premium : une écoute par histoire (US-37).
create function public.story_for_voice(p_user_id uuid, p_story_id uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_story public.stories;
  v_is_premium boolean := public.is_premium(p_user_id);
begin
  select * into v_story from public.stories where id = p_story_id and user_id = p_user_id and not is_hidden;
  if not found then
    raise exception 'INVALID_INPUT';
  end if;
  if not (v_is_premium or exists (select 1 from public.entitlements where user_id = p_user_id and has_voice_pack))
     or (v_story.listens_count > 0 and not v_is_premium) then
    raise exception 'LOCKED';
  end if;
  return jsonb_build_object('title', v_story.title, 'paragraphs', v_story.paragraphs, 'hero_name', v_story.hero_name);
end
$$;

-- Pack Voix : achat définitif (H9) ; un remboursement le retire.
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

  if p_event ->> 'product_id' = 'pack_voix' then
    if v_type in ('NON_RENEWING_PURCHASE', 'CANCELLATION') then
      insert into public.entitlements (user_id, has_voice_pack) values (v_user, v_type = 'NON_RENEWING_PURCHASE')
      on conflict (user_id) do update set has_voice_pack = excluded.has_voice_pack, updated_at = now();
    end if;
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

revoke execute on function public.story_for_voice(uuid, uuid) from public, anon, authenticated;
grant execute on function public.story_for_voice(uuid, uuid) to service_role;
