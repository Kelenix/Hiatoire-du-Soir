// Audio des voix apaisantes dans Storage (docs/data-model.md §5). Il contient le prénom : il part
// avec l'histoire (H13) et avec le compte (US-21).
import type { SupabaseClient } from 'npm:@supabase/supabase-js@2.119.0';

export const AUDIO_BUCKET = 'story-audio';

const PAGE = 1000;

/** Un dossier par famille, le seul qu'elle puisse lire (RLS). */
export const storyAudioPath = (userId: string, storyId: string, voiceId: string) =>
  `${userId}/${storyId}-${voiceId}.mp3`;

/** Supprime l'audio des histoires qui ne sont pas dans `keep` ; sans `keep`, tout l'audio de la famille. */
export async function removeStoryAudio(supabase: SupabaseClient, userId: string, keep = new Set<string>()) {
  const bucket = supabase.storage.from(AUDIO_BUCKET);
  const paths: string[] = [];
  for (let offset = 0; ; offset += PAGE) {
    const { data, error } = await bucket.list(userId, { limit: PAGE, offset });
    if (error) throw error;
    paths.push(
      ...data
        .filter((file) => !keep.has(file.name.slice(0, 36))) // identifiant de l'histoire (uuid)
        .map((file) => `${userId}/${file.name}`),
    );
    if (data.length < PAGE) break;
  }
  for (let start = 0; start < paths.length; start += PAGE) {
    const removal = await bucket.remove(paths.slice(start, start + PAGE));
    if (removal.error) throw removal.error;
  }
}
