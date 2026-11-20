-- Inc-5 : événements d'achat, droits Premium et règles de l'offre.
begin;
create extension if not exists pgtap with schema extensions;
select plan(16);

insert into auth.users (id, email, is_anonymous) values
  ('00000000-0000-0000-0000-00000000000a', 'parent-a@test.local', false),
  ('00000000-0000-0000-0000-00000000000b', 'parent-b@test.local', false);
insert into public.stories (id, user_id, theme_id, duration_min, title, paragraphs, listens_count) values
  ('70000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a', 'animaux', 2, 'Écoutée', array['p'], 1);

create function pg_temp.event(p_id text, p_type text, p_user text, p_expires_in interval, p_extra jsonb default '{}')
returns jsonb language sql as $$
  select jsonb_build_object(
    'id', p_id, 'type', p_type, 'app_user_id', p_user, 'product_id', 'premium_annuel',
    'entitlement_ids', jsonb_build_array('premium'),
    'event_timestamp_ms', (extract(epoch from now()) * 1000)::bigint,
    'expiration_at_ms', (extract(epoch from now() + p_expires_in) * 1000)::bigint
  ) || p_extra
$$;

-- Avant achat : offre gratuite
select is(public.is_premium('00000000-0000-0000-0000-00000000000a'), false, 'pas Premium avant achat');
select throws_ok($$ select public.precheck_generation('00000000-0000-0000-0000-00000000000a', 'ocean', 2::smallint) $$,
  'P0001', 'LOCKED', 'thème Premium verrouillé avant achat');

-- Achat (essai de 7 jours) via le webhook
select public.apply_purchase_event(pg_temp.event('evt-1', 'INITIAL_PURCHASE', '00000000-0000-0000-0000-00000000000a', '7 days'));
select is(public.is_premium('00000000-0000-0000-0000-00000000000a'), true, 'Premium actif après l''achat');
select is(public.precheck_generation('00000000-0000-0000-0000-00000000000a', 'ocean', 10::smallint), 'premium',
  'Premium : tous les thèmes et toutes les durées');

-- Idempotence : même événement rejoué
select public.apply_purchase_event(pg_temp.event('evt-1', 'INITIAL_PURCHASE', '00000000-0000-0000-0000-00000000000a', '7 days'));
select is((select count(*) from public.purchase_events where event_id = 'evt-1'), 1::bigint,
  'événement rejoué : enregistré une seule fois');

-- Identifiant anonyme RevenueCat, mais alias = utilisateur Supabase
select public.apply_purchase_event(pg_temp.event('evt-2', 'RENEWAL', '$RCAnonymousID:abc', '1 year',
  jsonb_build_object('aliases', jsonb_build_array('$RCAnonymousID:abc', '00000000-0000-0000-0000-00000000000b'))));
select is(public.is_premium('00000000-0000-0000-0000-00000000000b'), true, 'acheteur retrouvé par ses alias');

-- Résiliation simple : Premium jusqu'à la fin de la période
select public.apply_purchase_event(pg_temp.event('evt-3', 'CANCELLATION', '00000000-0000-0000-0000-00000000000a', '7 days',
  '{"cancel_reason": "UNSUBSCRIBE"}'));
select is(public.is_premium('00000000-0000-0000-0000-00000000000a'), true, 'résiliation : Premium jusqu''au terme');

-- Remboursement : Premium retiré tout de suite
select public.apply_purchase_event(pg_temp.event('evt-4', 'CANCELLATION', '00000000-0000-0000-0000-00000000000b', '1 year',
  '{"cancel_reason": "CUSTOMER_SUPPORT"}'));
select is(public.is_premium('00000000-0000-0000-0000-00000000000b'), false, 'remboursement : Premium retiré');

-- Acheteur inconnu : ignoré sans erreur
select lives_ok($$ select public.apply_purchase_event(pg_temp.event('evt-5', 'INITIAL_PURCHASE',
  '$RCAnonymousID:inconnu', '7 days')) $$, 'acheteur inconnu ignoré');

-- Plafond anti-abus (H19)
insert into public.generations (user_id, request_id, source, theme_id, duration_min)
select '00000000-0000-0000-0000-00000000000a', gen_random_uuid(), 'premium', 'animaux', 2 from generate_series(1, 30);
select throws_ok($$ select public.precheck_generation('00000000-0000-0000-0000-00000000000a', 'animaux', 2::smallint) $$,
  'P0001', 'ABUSE_LIMIT', '31e histoire en 24 h refusée');

-- Droits vus par l'app, écoutes et favoris illimités
set local role authenticated;
set local request.jwt.claims = '{"sub": "00000000-0000-0000-0000-00000000000a", "role": "authenticated"}';
select is((public.my_entitlements() ->> 'is_premium')::boolean, true, 'l''app voit le Premium');
select is((public.my_entitlements() ->> 'is_anonymous')::boolean, false, 'l''app sait que le compte est confirmé');
select lives_ok($$ select public.start_listening('70000000-0000-0000-0000-000000000001') $$, 'Premium : réécoute permise');
select is((select count(*) from public.entitlements), 0::bigint, 'droits illisibles directement');

-- Expiration
reset role;
select public.apply_purchase_event(pg_temp.event('evt-6', 'EXPIRATION', '00000000-0000-0000-0000-00000000000a', '0 seconds'));
select is(public.is_premium('00000000-0000-0000-0000-00000000000a'), false, 'expiration : retour à l''offre gratuite');
select throws_ok($$ select public.precheck_generation('00000000-0000-0000-0000-00000000000a', 'ocean', 2::smallint) $$,
  'P0001', 'LOCKED', 'après expiration, thèmes Premium verrouillés');

select * from finish();
rollback;
