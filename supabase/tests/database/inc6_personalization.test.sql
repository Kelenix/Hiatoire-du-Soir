-- Inc-6 : personnages, histoires sur mesure, prénom gardé hors du texte.
begin;
create extension if not exists pgtap with schema extensions;
select plan(13);

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a', 'parent-a@test.local'),
  ('00000000-0000-0000-0000-00000000000b', 'parent-b@test.local');
insert into public.characters (id, user_id, name, gender, animal, trait) values
  ('80000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a', 'Léa', 'girl', 'lapin', 'doux');

-- Accès : le parent B
set local role authenticated;
set local request.jwt.claims = '{"sub": "00000000-0000-0000-0000-00000000000b", "role": "authenticated"}';
select is((select count(*) from public.characters where user_id is null), 4::bigint, 'personnages prêts visibles par tous');
select is((select count(*) from public.characters where user_id is not null), 0::bigint,
  'les personnages d''une autre famille sont invisibles');
select throws_ok($$ insert into public.characters (user_id, name, gender, animal, trait)
  values ('00000000-0000-0000-0000-00000000000a', 'Intrus', 'boy', 'chat', 'malin') $$,
  '42501', null, 'impossible de créer un personnage pour une autre famille');
select lives_ok($$ insert into public.characters (user_id, name, gender, animal, trait)
  values ('00000000-0000-0000-0000-00000000000b', 'Tom', 'boy', 'chat', 'malin') $$, 'le parent crée son personnage');
select throws_ok($$ insert into public.characters (user_id, name, gender, animal, trait)
  values ('00000000-0000-0000-0000-00000000000b', 'Rex', 'boy', 'tyrannosaure', 'malin') $$,
  '23514', null, 'animal hors liste refusé');
select lives_ok($$ insert into public.characters (user_id, name, gender, animal, trait)
  select '00000000-0000-0000-0000-00000000000b', 'Enfant ' || n, 'neutral', 'ours', 'reveur' from generate_series(2, 10) n $$,
  'jusqu''à 10 personnages');
select throws_ok($$ insert into public.characters (user_id, name, gender, animal, trait)
  values ('00000000-0000-0000-0000-00000000000b', 'Onzième', 'girl', 'chat', 'doux') $$,
  'P0001', 'CHARACTERS_LIMIT', 'le 11e personnage est refusé');
select is((select count(*) from public.situations), 6::bigint, 'situations lisibles');

-- Offre : personnalisation réservée au Premium (ou aux crédits, Inc-7)
reset role;
select throws_ok($$ select public.precheck_generation('00000000-0000-0000-0000-00000000000a', 'animaux', 2::smallint, true) $$,
  'P0001', 'LOCKED', 'histoire sur mesure verrouillée en gratuit');
select is(public.precheck_generation('00000000-0000-0000-0000-00000000000a', 'animaux', 2::smallint, false), 'free',
  'personnage prêt à l''emploi : accessible en gratuit');
insert into public.entitlements (user_id, premium_until) values ('00000000-0000-0000-0000-00000000000a', now() + interval '1 day');
select is(public.precheck_generation('00000000-0000-0000-0000-00000000000a', 'animaux', 2::smallint, true), 'premium',
  'histoire sur mesure ouverte en Premium');

-- Prénom gardé à part, jamais dans le texte
select public.commit_generation('00000000-0000-0000-0000-00000000000a', '90000000-0000-0000-0000-000000000001',
  'animaux', 2::smallint, 'La nuit de {{HEROS}}', array['{{HEROS}} s''endort.'], 1, 1, 'Léa', 'girl', true);
select is((select hero_name from public.stories where title = 'La nuit de {{HEROS}}'), 'Léa', 'prénom gardé à part');
select is((select count(*) from public.stories where array_to_string(paragraphs, ' ') like '%Léa%'), 0::bigint,
  'le prénom n''apparaît pas dans le texte stocké');

select * from finish();
rollback;
