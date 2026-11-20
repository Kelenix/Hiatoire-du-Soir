-- Phase 5 : dépense Claude bornée, demande rejouée sans nouvel appel, fonctions fermées par défaut.
begin;
create extension if not exists pgtap with schema extensions;
select plan(9);

insert into auth.users (id, email, is_anonymous) values
  ('00000000-0000-0000-0000-0000000000f1', 'parent-f1@test.local', true);

create function pg_temp.start(p_request uuid) returns public.stories language sql as $$
  select public.start_generation('00000000-0000-0000-0000-0000000000f1', p_request)
$$;
create function pg_temp.finish(p_request uuid, p_spent boolean) returns void language sql as $$
  select public.finish_generation('00000000-0000-0000-0000-0000000000f1', p_request, p_spent)
$$;

select is((pg_temp.start('93000000-0000-0000-0000-000000000001')).id, null, 'première tentative acceptée');
select throws_ok($$ select pg_temp.start('93000000-0000-0000-0000-000000000002') $$, 'P0001', 'BUSY',
  'une seule création en cours par compte (requêtes simultanées)');

-- Refus avant tout appel à Claude : la tentative ne compte pas.
select pg_temp.finish('93000000-0000-0000-0000-000000000001', false);
select is((select sum(tries) from public.generation_attempts
           where user_id = '00000000-0000-0000-0000-0000000000f1'), 0::bigint, 'tentative sans dépense non comptée');

-- La même demande relancée en boucle compte à chaque fois : 10 tentatives par 24 h hors Premium.
do $$
begin
  for i in 1..10 loop
    perform pg_temp.start('93000000-0000-0000-0000-000000000003');
    perform pg_temp.finish('93000000-0000-0000-0000-000000000003', true);
  end loop;
end $$;
select throws_ok($$ select pg_temp.start('93000000-0000-0000-0000-000000000004') $$, 'P0001', 'ABUSE_LIMIT',
  'hors Premium : 10 tentatives par 24 h, échecs compris');
insert into public.entitlements (user_id, premium_until) values ('00000000-0000-0000-0000-0000000000f1', now() + interval '1 day');
select is((pg_temp.start('93000000-0000-0000-0000-000000000004')).id, null, 'Premium : 40 tentatives par 24 h');

-- Demande déjà servie : l'histoire revient sans nouvel appel à Claude, même si le quota est atteint.
select pg_temp.finish('93000000-0000-0000-0000-000000000004', true);
select public.commit_generation('00000000-0000-0000-0000-0000000000f1', '93000000-0000-0000-0000-000000000005',
  'animaux', 2::smallint, 'Le hibou', array['Il dort.'], 1, 1);
update public.entitlements set premium_until = null where user_id = '00000000-0000-0000-0000-0000000000f1';
select is((pg_temp.start('93000000-0000-0000-0000-000000000005')).title, 'Le hibou',
  'demande rejouée : histoire renvoyée, ni quota ni nouvel appel');

-- Fonctions réservées au serveur, et toute nouvelle fonction fermée par défaut.
select ok(not has_function_privilege('authenticated', 'public.start_generation(uuid, uuid)', 'execute'),
  'start_generation : serveur seul');
create function public.essai_privileges() returns int language sql as 'select 1';
select ok(not has_function_privilege('anon', 'public.essai_privileges()', 'execute'),
  'nouvelle fonction : fermée à anon par défaut');
select ok(not has_function_privilege('authenticated', 'public.essai_privileges()', 'execute'),
  'nouvelle fonction : fermée aux utilisateurs connectés par défaut');

select * from finish();
rollback;
