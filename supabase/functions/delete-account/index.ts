// Supprime définitivement le compte de l'appelant et ses données (US-21, docs/system-design.md §2.8).
// Les tables liées au compte suivent par suppression en cascade.
import { createClient } from 'npm:@supabase/supabase-js@2.119.0';

import { fail, requestUser } from '../_shared/http.ts';
import { removeStoryAudio } from '../_shared/story-audio.ts';

const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);

Deno.serve(async (request) => {
  if (request.method !== 'POST') return fail('INVALID_INPUT');

  const user = await requestUser(supabase, request);
  if (!user) return fail('UNAUTHORIZED');

  try {
    // L'audio (avec le prénom) d'abord : une fois le compte supprimé, plus rien ne le relierait à la famille.
    await removeStoryAudio(supabase, user.id);
    const { error } = await supabase.auth.admin.deleteUser(user.id);
    if (error) throw error;
  } catch (error) {
    console.error('Suppression du compte impossible', error instanceof Error ? error.message : error);
    return fail('UPSTREAM_ERROR');
  }
  return Response.json({ deleted: true });
});
