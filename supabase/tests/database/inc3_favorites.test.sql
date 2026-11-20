-- Inc-3 : favoris, limite de 3 en gratuit, histoires gardées (H13).
begin;
create extension if not exists pgtap with schema extensions;
select plan(9);

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a', 'parent-a@test.local'),
  ('00000000-0000-0000-0000-00000000000b', 'parent-b@test.local');
insert into public.stories (id, user_id, theme_id, duration_min, title, paragraphs) values
  ('40000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a', 'animaux', 2, 'Un', array['p']),
  ('40000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-00000000000a', 'animaux', 2, 'Deux', array['p']),
  ('40000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-00000000000a', 'animaux', 2, 'Trois', array['p']),
  ('40000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-00000000000a', 'animaux', 2, 'Quatre', array['p']);

set local role authenticated;
set local request.jwt.claims = '{"sub": "00000000-0000-0000-0000-00000000000b", "role": "authenticated"}';
select throws_ok($$ select public.set_favorite('40000000-0000-0000-0000-000000000001', true) $$,
  'P0001', 'INVALID_INPUT', 'impossible de mettre en favori l''histoire d''un autre compte');

set local request.jwt.claims = '{"sub": "00000000-0000-0000-0000-00000000000a", "role": "authenticated"}';
select lives_ok($$ select public.set_favorite('40000000-0000-0000-0000-000000000001', true) $$, '1er favori');
select lives_ok($$ select public.set_favorite('40000000-0000-0000-0000-000000000002', true) $$, '2e favori');
select lives_ok($$ select public.set_favorite('40000000-0000-0000-0000-000000000003', true) $$, '3e favori');
select throws_ok($$ select public.set_favorite('40000000-0000-0000-0000-000000000004', true) $$,
  'P0001', 'FAVORITES_LIMIT', '4e favori refusé en gratuit');
select lives_ok($$ select public.set_favorite('40000000-0000-0000-0000-000000000003', true) $$,
  'remettre en favori une histoire déjà favorite reste possible');
select lives_ok($$ select public.set_favorite('40000000-0000-0000-0000-000000000003', false) $$, 'retirer un favori');
select lives_ok($$ select public.set_favorite('40000000-0000-0000-0000-000000000004', true) $$,
  'une place libérée permet un nouveau favori');

-- H13 : une nouvelle histoire garde les favoris et supprime le reste
reset role;
select public.commit_generation('00000000-0000-0000-0000-00000000000a', '50000000-0000-0000-0000-000000000001',
  'animaux', 2::smallint, 'Nouvelle', array['p'], 1, 1);
select is(
  (select array_agg(title order by title) from public.stories where user_id = '00000000-0000-0000-0000-00000000000a'),
  array['Deux', 'Nouvelle', 'Quatre', 'Un'],
  'favoris et dernière histoire gardés, le reste supprimé');

select * from finish();
rollback;
