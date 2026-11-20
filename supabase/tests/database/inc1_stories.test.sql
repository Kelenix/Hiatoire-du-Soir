-- Inc-1 : quota gratuit, idempotence, histoires gardées (H13) et règles d'accès (RLS).
begin;
create extension if not exists pgtap with schema extensions;
select plan(18);

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a', 'parent-a@test.local'),
  ('00000000-0000-0000-0000-00000000000b', 'parent-b@test.local');

create function pg_temp.create_story(p_user uuid, p_request uuid, p_theme text default 'animaux', p_duration smallint default 2)
returns public.stories language sql as $$
  select public.commit_generation(p_user, p_request, p_theme, p_duration, 'Titre', array['Il était une fois…'], 100, 500)
$$;

-- Quota gratuit (US-07)
select is(public.free_stories_left('00000000-0000-0000-0000-00000000000a'), 3, 'nouveau compte : 3 histoires gratuites');
select lives_ok($$ select pg_temp.create_story('00000000-0000-0000-0000-00000000000a', '10000000-0000-0000-0000-000000000001') $$, '1re histoire');
select lives_ok($$ select pg_temp.create_story('00000000-0000-0000-0000-00000000000a', '10000000-0000-0000-0000-000000000002') $$, '2e histoire');
select lives_ok($$ select pg_temp.create_story('00000000-0000-0000-0000-00000000000a', '10000000-0000-0000-0000-000000000003') $$, '3e histoire');
select is(public.free_stories_left('00000000-0000-0000-0000-00000000000a'), 0, 'quota épuisé après 3 histoires');
select throws_ok($$ select pg_temp.create_story('00000000-0000-0000-0000-00000000000a', '10000000-0000-0000-0000-000000000004') $$,
  'P0001', 'QUOTA_REACHED', '4e histoire de la semaine refusée');

-- Idempotence : une demande rejouée renvoie la même histoire sans consommer
select is(
  (pg_temp.create_story('00000000-0000-0000-0000-00000000000a', '10000000-0000-0000-0000-000000000003')).id,
  (select story_id from public.generations where request_id = '10000000-0000-0000-0000-000000000003'),
  'demande rejouée : même histoire');
select is((select count(*) from public.generations where user_id = '00000000-0000-0000-0000-00000000000a'), 3::bigint,
  'demande rejouée : rien de consommé en plus');

-- H13 : seule la dernière histoire est gardée
select is((select count(*) from public.stories where user_id = '00000000-0000-0000-0000-00000000000a'), 1::bigint,
  'une seule histoire gardée');

-- Offre gratuite : thèmes et durées
select throws_ok($$ select public.precheck_generation('00000000-0000-0000-0000-00000000000b', 'ocean', 2::smallint) $$,
  'P0001', 'LOCKED', 'thème Premium verrouillé en gratuit');
select throws_ok($$ select public.precheck_generation('00000000-0000-0000-0000-00000000000b', 'animaux', 5::smallint) $$,
  'P0001', 'LOCKED', 'durée de 5 minutes verrouillée en gratuit');
select throws_ok($$ select public.precheck_generation('00000000-0000-0000-0000-00000000000b', 'inconnu', 2::smallint) $$,
  'P0001', 'INVALID_INPUT', 'thème inconnu refusé');

-- RLS : le parent B, connecté
set local role authenticated;
set local request.jwt.claims = '{"sub": "00000000-0000-0000-0000-00000000000b", "role": "authenticated"}';

select is((select count(*) from public.themes), 9::bigint, 'catalogue lisible');
select is((select count(*) from public.stories), 0::bigint, 'B ne voit pas les histoires de A');
select is((select count(*) from public.generations), 0::bigint, 'journal des générations illisible');
select throws_ok($$ insert into public.stories (user_id, theme_id, duration_min, title, paragraphs)
  values ('00000000-0000-0000-0000-00000000000b', 'animaux', 2, 'x', array['y']) $$,
  '42501', null, 'écriture directe d''une histoire interdite');
select throws_ok($$ select pg_temp.create_story('00000000-0000-0000-0000-00000000000b', '20000000-0000-0000-0000-000000000001') $$,
  '42501', null, 'création réservée au serveur');
select is((public.my_entitlements() ->> 'free_stories_left')::integer, 3, 'droits de B : 3 histoires gratuites');

select * from finish();
rollback;
