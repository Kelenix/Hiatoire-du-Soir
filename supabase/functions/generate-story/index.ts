// Crée une histoire (docs/system-design.md §2.2). Le serveur décide de tout ce qui coûte (ADR-003).
import Anthropic from 'npm:@anthropic-ai/sdk@1.6.0';
import { createClient } from 'npm:@supabase/supabase-js@2.119.0';
import { z } from 'npm:zod@4.6.7';

import { fail, failFromDatabase, requestUser } from '../_shared/http.ts';
import { removeStoryAudio } from '../_shared/story-audio.ts';
import { ANIMALS, cleanParentText, ContentRejected, writeSafeStory } from './story.ts';

const slug = z.string().regex(/^[a-z0-9-]{2,40}$/);
const requestSchema = z.object({
  request_id: z.uuid(),
  theme_id: slug,
  duration_min: z.union([z.literal(2), z.literal(5), z.literal(10)]),
  // Options sur mesure (US-32) : héros, animal, situation de la liste OU texte libre du parent.
  character_id: z.uuid().optional(),
  animal: z.enum(ANIMALS).optional(),
  situation_id: slug.optional(),
  situation_text: z.string().trim().min(3).max(150).optional(),
}).refine((input) => !(input.situation_id && input.situation_text));

const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
const anthropic = new Anthropic({ timeout: 45_000, maxRetries: 1 });

/** Les histoires non gardées viennent d'être supprimées (H13) : leur audio aussi. Un échec sera rattrapé
 * à la création suivante, qui repasse sur tout le dossier ; il ne fait pas échouer celle-ci. */
async function removeAudioOfDeletedStories(userId: string) {
  try {
    const stories = await supabase.from('stories').select('id').eq('user_id', userId);
    if (stories.error) throw stories.error;
    await removeStoryAudio(supabase, userId, new Set(stories.data.map((story) => story.id)));
  } catch (error) {
    console.error('Audio des histoires supprimées non effacé', error instanceof Error ? error.message : error);
  }
}

Deno.serve(async (request) => {
  if (request.method !== 'POST') return fail('INVALID_INPUT');

  const user = await requestUser(supabase, request);
  if (!user) return fail('UNAUTHORIZED');

  const input = requestSchema.safeParse(await request.json().catch(() => null));
  if (!input.success) return fail('INVALID_INPUT');
  const { request_id, theme_id, duration_min, character_id, animal, situation_id, situation_text } = input.data;

  // Demande déjà servie (réponse perdue, « Réessayer ») : l'histoire revient sans nouvel appel à Claude.
  // Sinon la tentative est réservée : une création à la fois, tentatives bornées (ADR-036).
  const attempt = await supabase.rpc('start_generation', { p_user_id: user.id, p_request_id: request_id });
  if (attempt.error) return failFromDatabase(attempt.error);
  if (attempt.data?.id) return Response.json({ story: attempt.data });

  let hasSpent = false;
  try {
    // Clé de service : la base ne filtre pas, on ne lit que les personnages prêts ou ceux de ce parent.
    const [theme, character, situation] = await Promise.all([
      supabase.from('themes').select('name, writing_guide').eq('id', theme_id).maybeSingle(),
      character_id
        ? supabase.from('characters').select('name, gender, animal, trait, user_id')
          .eq('id', character_id).or(`user_id.is.null,user_id.eq.${user.id}`).maybeSingle()
        : null,
      situation_id
        ? supabase.from('situations').select('writing_guide').eq('id', situation_id).eq('is_active', true).maybeSingle()
        : null,
    ]);
    const databaseError = theme.error ?? character?.error ?? situation?.error;
    if (databaseError) return failFromDatabase(databaseError);
    if (!theme.data || (character && !character.data) || (situation && !situation.data)) return fail('INVALID_INPUT');

    const hero = character?.data;
    // Un personnage prêt à l'emploi reste gratuit ; le reste est sur mesure (Premium ou crédit).
    const personalized = Boolean(hero?.user_id || animal || situation_id || situation_text);
    const target = { p_user_id: user.id, p_theme_id: theme_id, p_duration_min: duration_min, p_personalized: personalized };

    const precheck = await supabase.rpc('precheck_generation', target);
    if (precheck.error) return failFromDatabase(precheck.error);

    hasSpent = true;
    const story = await writeSafeStory(anthropic, {
      theme: theme.data,
      durationMin: duration_min,
      hero: hero ? { gender: hero.gender, animal: hero.animal, trait: hero.trait, isPreset: hero.user_id === null } : undefined,
      animal,
      situation: situation?.data
        ? { guide: situation.data.writing_guide }
        : situation_text ? { parentText: cleanParentText(situation_text, hero?.name) } : undefined,
    });
    const commit = await supabase.rpc('commit_generation', {
      ...target,
      p_request_id: request_id,
      p_title: story.title,
      p_paragraphs: story.paragraphs,
      p_input_tokens: story.inputTokens,
      p_output_tokens: story.outputTokens,
      p_hero_name: hero?.name ?? null,
      p_hero_gender: hero?.gender ?? null,
    });
    if (commit.error) return failFromDatabase(commit.error);
    await removeAudioOfDeletedStories(user.id);
    return Response.json({ story: commit.data });
  } catch (error) {
    if (error instanceof ContentRejected) return fail('CONTENT_REJECTED');
    console.error('Échec de l’écriture', error instanceof Error ? error.message : error);
    return fail('UPSTREAM_ERROR');
  } finally {
    const finish = await supabase.rpc('finish_generation', {
      p_user_id: user.id,
      p_request_id: request_id,
      p_has_spent: hasSpent,
    });
    if (finish.error) console.error('Tentative non clôturée', finish.error.message);
  }
});
