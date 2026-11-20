-- Inc-4 : signalement d'une histoire.
begin;
create extension if not exists pgtap with schema extensions;
select plan(7);

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a', 'parent-a@test.local'),
  ('00000000-0000-0000-0000-00000000000b', 'parent-b@test.local');
insert into public.stories (id, user_id, theme_id, duration_min, title, paragraphs, is_favorite, favorited_at) values
  ('60000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a', 'animaux', 2, 'Signalée', array['Texte'], true, now());

set local role authenticated;
set local request.jwt.claims = '{"sub": "00000000-0000-0000-0000-00000000000b", "role": "authenticated"}';
select throws_ok($$ select public.report_story('60000000-0000-0000-0000-000000000001', 'scary', null) $$,
  'P0001', 'INVALID_INPUT', 'impossible de signaler l''histoire d''un autre compte');

set local request.jwt.claims = '{"sub": "00000000-0000-0000-0000-00000000000a", "role": "authenticated"}';
select lives_ok($$ select public.report_story('60000000-0000-0000-0000-000000000001', 'scary', '  Trop effrayant  ') $$,
  'signalement enregistré');
select is((select count(*) from public.stories where title = 'Signalée'), 0::bigint,
  'l''histoire signalée disparaît de l''app');
select throws_ok($$ select public.set_favorite('60000000-0000-0000-0000-000000000001', true) $$,
  'P0001', 'INVALID_INPUT', 'une histoire signalée ne revient pas en favori');
select is((select count(*) from public.story_reports), 0::bigint, 'signalements illisibles depuis l''app');

reset role;
select is((select comment from public.story_reports where title = 'Signalée'), 'Trop effrayant',
  'commentaire nettoyé et gardé');
select is((select is_favorite from public.stories where id = '60000000-0000-0000-0000-000000000001'), false,
  'favori retiré');

select * from finish();
rollback;
