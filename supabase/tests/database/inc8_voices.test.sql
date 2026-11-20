-- Inc-8 : voix apaisantes et Pack Voix (US-36, US-37, H9).
begin;
create extension if not exists pgtap with schema extensions;
select plan(13);

insert into auth.users (id, email, is_anonymous) values
  ('00000000-0000-0000-0000-00000000000d', 'parent-d@test.local', false),
  ('00000000-0000-0000-0000-00000000000e', 'parent-e@test.local', false);
insert into public.stories (id, user_id, theme_id, duration_min, title, paragraphs, hero_name) values
  ('92000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000d', 'animaux', 2,
   'La nuit de {{HEROS}}', array['{{HEROS}} dort.'], 'Emma'),
  ('92000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-00000000000e', 'animaux', 2,
   'Ailleurs', array['Une autre famille.'], null);

create function pg_temp.event(p_id text, p_type text) returns jsonb language sql as $$
  select jsonb_build_object('id', p_id, 'type', p_type, 'product_id', 'pack_voix',
    'app_user_id', '00000000-0000-0000-0000-00000000000d', 'event_timestamp_ms', 1763600000000)
$$;
create function pg_temp.story(p_story uuid) returns jsonb language sql as $$
  select public.story_for_voice('00000000-0000-0000-0000-00000000000d', p_story)
$$;

select throws_ok($$ select pg_temp.story('92000000-0000-0000-0000-000000000001') $$, 'P0001', 'LOCKED',
  'sans Premium ni Pack Voix : voix apaisantes verrouillées');

-- Achat du Pack Voix (webhook), rejoué : enregistré une fois.
select public.apply_purchase_event(pg_temp.event('evt-voix', 'NON_RENEWING_PURCHASE'));
select public.apply_purchase_event(pg_temp.event('evt-voix', 'NON_RENEWING_PURCHASE'));
select is((select has_voice_pack from public.entitlements where user_id = '00000000-0000-0000-0000-00000000000d'),
  true, 'Pack Voix enregistré');
select is(pg_temp.story('92000000-0000-0000-0000-000000000001'),
  '{"title": "La nuit de {{HEROS}}", "paragraphs": ["{{HEROS}} dort."], "hero_name": "Emma"}'::jsonb,
  'Pack Voix : texte avec le marqueur et le prénom à part');
select throws_ok($$ select pg_temp.story('92000000-0000-0000-0000-000000000002') $$, 'P0001', 'INVALID_INPUT',
  'jamais l’histoire d’une autre famille');

-- En gratuit, une écoute par histoire, même avec le Pack Voix (US-37).
update public.stories set listens_count = 1 where id = '92000000-0000-0000-0000-000000000001';
select throws_ok($$ select pg_temp.story('92000000-0000-0000-0000-000000000001') $$, 'P0001', 'LOCKED',
  'Pack Voix sans Premium : histoire déjà écoutée verrouillée');
update public.entitlements set premium_until = now() + interval '1 month'
where user_id = '00000000-0000-0000-0000-00000000000d';
select is(pg_temp.story('92000000-0000-0000-0000-000000000001') ->> 'hero_name', 'Emma',
  'Premium : réécoute permise');

-- Remboursement : Pack Voix retiré.
update public.entitlements set premium_until = null where user_id = '00000000-0000-0000-0000-00000000000d';
select public.apply_purchase_event(pg_temp.event('evt-voix-refund', 'CANCELLATION'));
select throws_ok($$ select pg_temp.story('92000000-0000-0000-0000-000000000001') $$, 'P0001', 'LOCKED',
  'Pack Voix remboursé : voix de nouveau verrouillées');

-- Audio : bucket privé ; chaque famille ne lit que son dossier et les extraits.
select is((select public from storage.buckets where id = 'story-audio'), false, 'bucket audio privé');
insert into storage.objects (bucket_id, name) values
  ('story-audio', '00000000-0000-0000-0000-00000000000d/92000000-0000-0000-0000-000000000001-douce.mp3'),
  ('story-audio', '00000000-0000-0000-0000-00000000000e/92000000-0000-0000-0000-000000000002-douce.mp3'),
  ('story-audio', 'extraits/essai-test.mp3');

set local role authenticated;
set local request.jwt.claims = '{"sub": "00000000-0000-0000-0000-00000000000d", "role": "authenticated"}';
select is((select count(*) from public.voices), 3::bigint, '3 voix apaisantes proposées');
select is(public.my_entitlements() -> 'has_voice_pack', 'false'::jsonb, 'droits : Pack Voix lisible par le parent');
select throws_ok($$ select public.story_for_voice('00000000-0000-0000-0000-00000000000d',
  '92000000-0000-0000-0000-000000000001') $$, '42501', null, 'texte pour la voix : serveur seul');
select is((select array_agg(name order by name) from storage.objects
           where bucket_id = 'story-audio' and (name like '00000000-0000-0000-0000-00000000000_/%' or name like 'extraits/essai-test%')),
  array['00000000-0000-0000-0000-00000000000d/92000000-0000-0000-0000-000000000001-douce.mp3', 'extraits/essai-test.mp3'],
  'audio lisible : le sien et les extraits, pas celui des autres familles');
select throws_ok($$ insert into storage.objects (bucket_id, name)
  values ('story-audio', '00000000-0000-0000-0000-00000000000d/x-douce.mp3') $$, '42501', null,
  'aucune écriture d’audio depuis l’app');

select * from finish();
rollback;
