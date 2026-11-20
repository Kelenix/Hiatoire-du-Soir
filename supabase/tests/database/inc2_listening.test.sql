-- Inc-2 : une écoute par histoire en gratuit, uniquement sur ses propres histoires.
begin;
create extension if not exists pgtap with schema extensions;
select plan(5);

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a', 'parent-a@test.local'),
  ('00000000-0000-0000-0000-00000000000b', 'parent-b@test.local');
insert into public.stories (id, user_id, theme_id, duration_min, title, paragraphs) values
  ('30000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a', 'animaux', 2, 'Titre', array['Texte']);

set local role authenticated;
set local request.jwt.claims = '{"sub": "00000000-0000-0000-0000-00000000000b", "role": "authenticated"}';
select throws_ok($$ select public.start_listening('30000000-0000-0000-0000-000000000001') $$,
  'P0001', 'INVALID_INPUT', 'impossible d''écouter l''histoire d''un autre compte');

set local request.jwt.claims = '{"sub": "00000000-0000-0000-0000-00000000000a", "role": "authenticated"}';
select lives_ok($$ select public.start_listening('30000000-0000-0000-0000-000000000001') $$, '1re écoute autorisée');
select is((select listens_count from public.stories where id = '30000000-0000-0000-0000-000000000001'), 1, 'écoute décomptée');
select throws_ok($$ select public.start_listening('30000000-0000-0000-0000-000000000001') $$,
  'P0001', 'LOCKED', '2e écoute refusée en gratuit');
update public.stories set listens_count = 0;  -- sans policy UPDATE, la RLS ignore la ligne
select is((select listens_count from public.stories where id = '30000000-0000-0000-0000-000000000001'), 1,
  'compteur non modifiable directement');

select * from finish();
rollback;
