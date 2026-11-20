/** Le prénom ne quitte jamais nos serveurs pour l'IA : Claude écrit ce marqueur (ADR-017). */
export const HERO_MARKER = '{{HEROS}}';

const elision = /(?<!\p{L})(d|D|qu|Qu|lorsqu|Lorsqu|puisqu|Puisqu)e \{\{HEROS\}\}/gu;
const startsWithVowel = /^[aeiouyàâéèêëîïôûù]/i;

/** Remet le prénom dans le texte, avec l'élision (« d’Emma », « qu’Emma ») ; même règle que l'app. */
export function withHeroName(text: string, name: string | null): string {
  if (!name) return text;
  const elided = startsWithVowel.test(name) ? text.replace(elision, (_, word) => `${word}’${name}`) : text;
  return elided.replaceAll(HERO_MARKER, () => name);
}
