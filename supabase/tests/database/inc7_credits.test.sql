-- Inc-7 : packs, registre des crédits, ordre de consommation (US-33 à US-35, H8, H16).
begin;
create extension if not exists pgtap with schema extensions;
select plan(17);

insert into auth.users (id, email, is_anonymous) values
  ('00000000-0000-0000-0000-00000000000c', 'parent-c@test.local', false);

create function pg_temp.event(p_id text, p_type text, p_product text) returns jsonb language sql as $$
  select jsonb_build_object('id', p_id, 'type', p_type, 'product_id', p_product,
    'app_user_id', '00000000-0000-0000-0000-00000000000c', 'event_timestamp_ms', 1763600000000)
$$;
create function pg_temp.balance(p_scope public.credit_scope) returns integer language sql as $$
  select public.credit_balance('00000000-0000-0000-0000-00000000000c', p_scope)
$$;
create function pg_temp.source(p_theme text, p_minutes int, p_personalized boolean) returns public.generation_source
language sql as $$
  select public.precheck_generation('00000000-0000-0000-0000-00000000000c', p_theme, p_minutes::smallint, p_personalized)
$$;

-- Quota gratuit épuisé pour la suite.
insert into public.generations (user_id, request_id, source, theme_id, duration_min)
select '00000000-0000-0000-0000-00000000000c', gen_random_uuid(), 'free', 'animaux', 2 from generate_series(1, 3);

select throws_ok($$ select pg_temp.source('animaux', 2, false) $$, 'P0001', 'QUOTA_REACHED',
  'sans crédit : quota atteint pour une histoire gratuite');
select throws_ok($$ select pg_temp.source('noel', 2, false) $$, 'P0001', 'LOCKED', 'sans crédit : Noël verrouillé');

-- Achat d'un pack (webhook), rejoué : crédité une seule fois.
select public.apply_purchase_event(pg_temp.event('evt-noel', 'NON_RENEWING_PURCHASE', 'pack_noel_10'));
select public.apply_purchase_event(pg_temp.event('evt-noel', 'NON_RENEWING_PURCHASE', 'pack_noel_10'));
select is(pg_temp.balance('noel'), 10, 'Pack Noël : 10 crédits, une seule fois');

select is(pg_temp.source('noel', 10, true), 'credit', 'Noël : personnalisation et durée comprises');
select throws_ok($$ select pg_temp.source('ocean', 2, false) $$, 'P0001', 'LOCKED',
  'les crédits Noël ne servent pas aux autres thèmes');

-- Un crédit n'est décompté qu'à la création effective.
select public.commit_generation('00000000-0000-0000-0000-00000000000c', '91000000-0000-0000-0000-000000000001',
  'noel', 5::smallint, 'Neige', array['Il neige.'], 1, 1, null, null, false);
select is(pg_temp.balance('noel'), 9, 'histoire créée : un crédit Noël décompté');
select public.commit_generation('00000000-0000-0000-0000-00000000000c', '91000000-0000-0000-0000-000000000001',
  'noel', 5::smallint, 'Neige', array['Il neige.'], 1, 1, null, null, false);
select is(pg_temp.balance('noel'), 9, 'demande rejouée : rien de plus décompté');

-- Ordre H16 : pack du thème avant les crédits génériques.
select public.apply_purchase_event(pg_temp.event('evt-famille', 'NON_RENEWING_PURCHASE', 'pack_famille_30'));
select public.apply_purchase_event(pg_temp.event('evt-aventures', 'NON_RENEWING_PURCHASE', 'pack_aventures_10'));
select public.commit_generation('00000000-0000-0000-0000-00000000000c', '91000000-0000-0000-0000-000000000002',
  'noel', 2::smallint, 'Lutins', array['Les lutins dansent.'], 1, 1, null, null, false);
select is(pg_temp.balance('noel') || '/' || pg_temp.balance('generic'), '8/30', 'Noël : crédit Noël avant le générique');
select public.commit_generation('00000000-0000-0000-0000-00000000000c', '91000000-0000-0000-0000-000000000003',
  'ocean', 2::smallint, 'Vagues', array['La mer chante.'], 1, 1, null, null, false);
select is(pg_temp.balance('premium_themes') || '/' || pg_temp.balance('generic'), '9/30',
  'thème Premium : crédit Aventures avant le générique');
select public.commit_generation('00000000-0000-0000-0000-00000000000c', '91000000-0000-0000-0000-000000000004',
  'ocean', 2::smallint, 'Bulle', array['{{HEROS}} nage.'], 1, 1, 'Léa', 'girl', true);
select is(pg_temp.balance('premium_themes') || '/' || pg_temp.balance('generic'), '9/29',
  'histoire sur mesure : pas de crédit Aventures, le générique sert');
select public.apply_purchase_event(pg_temp.event('evt-sur-mesure', 'NON_RENEWING_PURCHASE', 'histoire_sur_mesure_1'));
select public.commit_generation('00000000-0000-0000-0000-00000000000c', '91000000-0000-0000-0000-000000000005',
  'animaux', 10::smallint, 'Forêt', array['{{HEROS}} rêve.'], 1, 1, 'Léa', 'girl', true);
select is(pg_temp.balance('custom') || '/' || pg_temp.balance('generic'), '0/29',
  'histoire sur mesure : crédit « sur mesure » avant le générique');

-- Le quota gratuit passe avant les crédits.
delete from public.generations where user_id = '00000000-0000-0000-0000-00000000000c' and source = 'free';
select is(pg_temp.source('animaux', 2, false), 'free', 'quota gratuit utilisé avant les crédits');
select is(pg_temp.source('animaux', 5, false), 'credit', 'hors offre gratuite : un crédit sert');

-- Remboursement : crédits retirés, même s'ils ont servi ; jamais de solde négatif affiché.
select public.apply_purchase_event(pg_temp.event('evt-noel-refund', 'CANCELLATION', 'pack_noel_10'));
select is(pg_temp.balance('noel'), -2, 'remboursement : les 10 crédits Noël retirés');

-- Côté parent : soldes visibles, registre inaccessible, packs lisibles.
set local role authenticated;
set local request.jwt.claims = '{"sub": "00000000-0000-0000-0000-00000000000c", "role": "authenticated"}';
select is(public.my_entitlements() -> 'credits', '{"generic": 29, "premium_themes": 9}'::jsonb,
  'soldes positifs seulement');
select is((select count(*) from public.credit_ledger), 0::bigint, 'registre illisible directement');
select is((select count(*) from public.credit_packs), 4::bigint, '4 packs proposés');

select * from finish();
rollback;
