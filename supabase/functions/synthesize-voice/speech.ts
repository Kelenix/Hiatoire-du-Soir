// Synthèse par Google Cloud Text-to-Speech (ADR-008) : voix neuronales, MP3.
import { withHeroName } from '../_shared/hero.ts';

/** Limite de Google : 5 000 octets par requête ; marge pour les accents (2 octets en UTF-8). */
const MAX_BYTES = 4800;

export type VoiceSettings = { provider_voice: string; speaking_rate: number };
export type StoredStory = { title: string; paragraphs: string[]; hero_name: string | null };

/** Texte lu : le titre puis l'histoire, prénom remis (même texte que la voix du téléphone). */
export const spokenText = ({ title, paragraphs, hero_name }: StoredStory) =>
  withHeroName(`${title}.\n\n${paragraphs.join('\n\n')}`, hero_name);

const bytes = (text: string) => new TextEncoder().encode(text).length;

/** Regroupe les morceaux tant que la limite le permet. */
function pack(parts: string[], separator: string): string[] {
  const chunks: string[] = [];
  for (const part of parts) {
    const joined = chunks.length ? `${chunks.at(-1)}${separator}${part}` : part;
    if (chunks.length && bytes(joined) <= MAX_BYTES) chunks[chunks.length - 1] = joined;
    else chunks.push(part);
  }
  return chunks;
}

/** Découpe entre deux paragraphes, ou entre deux mots pour un paragraphe trop long. */
export const speechChunks = (text: string) =>
  pack(text.split('\n\n').flatMap((paragraph) => bytes(paragraph) <= MAX_BYTES ? [paragraph] : pack(paragraph.split(' '), ' ')), '\n\n');

/** Morceaux synthétisés en parallèle (première écoute en moins de 10 s), puis MP3 mis bout à bout. */
export async function synthesize(text: string, voice: VoiceSettings, apiKey: string): Promise<Uint8Array> {
  const parts = await Promise.all(speechChunks(text).map(async (chunk) => {
    const response = await fetch('https://texttospeech.googleapis.com/v1/text:synthesize', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'X-Goog-Api-Key': apiKey },
      body: JSON.stringify({
        input: { text: chunk },
        voice: { languageCode: 'fr-FR', name: voice.provider_voice },
        audioConfig: { audioEncoding: 'MP3', speakingRate: voice.speaking_rate },
      }),
      signal: AbortSignal.timeout(15_000),
    });
    if (!response.ok) throw new Error(`Google Text-to-Speech : ${response.status} ${await response.text()}`);
    const { audioContent } = await response.json() as { audioContent: string };
    return Uint8Array.from(atob(audioContent), (character) => character.charCodeAt(0));
  }));
  return new Uint8Array(await new Blob(parts).arrayBuffer());
}
