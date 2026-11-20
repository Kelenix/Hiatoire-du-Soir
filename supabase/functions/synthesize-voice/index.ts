// Voix apaisantes (US-36, docs/system-design.md §2.4) : synthèse Google à la première écoute, puis audio
// gardé dans Storage. Sans histoire : l'extrait de la voix, que tout parent peut écouter avant d'acheter.
// L'app lit ensuite le fichier par une URL signée ; l'écoute est décomptée par start_listening.
import { createClient } from 'npm:@supabase/supabase-js@2.119.0';
import { z } from 'npm:zod@4.6.7';

import { fail, failFromDatabase, requestUser } from '../_shared/http.ts';
import { AUDIO_BUCKET, storyAudioPath } from '../_shared/story-audio.ts';
import { spokenText, type StoredStory, synthesize } from './speech.ts';

const requestSchema = z.object({ voice_id: z.string().regex(/^[a-z0-9-]{2,40}$/), story_id: z.uuid().optional() });

const SAMPLE_TEXT = 'Il était une fois, au bord d’une forêt tranquille, un petit renard qui regardait les étoiles. ' +
  'Il bâilla doucement, ferma les yeux, et s’endormit en souriant. Bonne nuit, petit renard.';

const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
const apiKey = Deno.env.get('GOOGLE_TTS_API_KEY');

Deno.serve(async (request) => {
  if (request.method !== 'POST') return fail('INVALID_INPUT');

  const user = await requestUser(supabase, request);
  if (!user) return fail('UNAUTHORIZED');

  const input = requestSchema.safeParse(await request.json().catch(() => null));
  if (!input.success) return fail('INVALID_INPUT');
  const { voice_id, story_id } = input.data;

  const voice = await supabase.from('voices').select('provider_voice, speaking_rate')
    .eq('id', voice_id).eq('is_active', true).maybeSingle();
  if (voice.error) return failFromDatabase(voice.error);
  if (!voice.data) return fail('INVALID_INPUT');

  let path = `extraits/${voice_id}.mp3`;
  let text = SAMPLE_TEXT;
  if (story_id) {
    // Droits (Premium ou Pack Voix) et écoute gratuite déjà utilisée : vérifiés avant toute dépense.
    const story = await supabase.rpc('story_for_voice', { p_user_id: user.id, p_story_id: story_id });
    if (story.error) return failFromDatabase(story.error);
    path = storyAudioPath(user.id, story_id, voice_id);
    text = spokenText(story.data as StoredStory);
  }

  const bucket = supabase.storage.from(AUDIO_BUCKET);
  try {
    if (!(await bucket.exists(path)).data) {
      if (!apiKey) throw new Error('clé GOOGLE_TTS_API_KEY absente');
      const audio = await synthesize(text, voice.data, apiKey);
      const upload = await bucket.upload(path, audio, { contentType: 'audio/mpeg', upsert: true });
      if (upload.error) throw upload.error;
      // Suivi du coût (R5) : Google facture au caractère.
      console.info('Voix synthétisée', voice_id, `${text.length} caractères`);
    }
  } catch (error) {
    console.error('Synthèse impossible', error instanceof Error ? error.message : error);
    return fail('UPSTREAM_ERROR');
  }
  return Response.json({ path });
});
