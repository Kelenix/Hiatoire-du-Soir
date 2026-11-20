// US-36 : le texte lu par la voix apaisante est celui de l'app, découpé selon la limite de Google.
import assert from 'node:assert/strict';

import { speechChunks, spokenText } from './speech.ts';

Deno.test('le prénom est remis, avec l’élision, après le titre', () => {
  assert.equal(spokenText({ title: 'Le hibou', paragraphs: ['Il dort.', 'La lune veille.'], hero_name: null }),
    'Le hibou.\n\nIl dort.\n\nLa lune veille.');
  assert.equal(
    spokenText({ title: 'La nuit de {{HEROS}}', paragraphs: ['Le chat de {{HEROS}} dort.'], hero_name: 'Emma' }),
    'La nuit d’Emma.\n\nLe chat d’Emma dort.',
  );
  assert.equal(spokenText({ title: 'T', paragraphs: ['Lorsque {{HEROS}} rit.'], hero_name: 'Léo' }), 'T.\n\nLorsque Léo rit.');
});

Deno.test('morceaux de 4 800 octets au plus, coupés entre paragraphes, texte intact', () => {
  const paragraphs = Array.from({ length: 40 }, (_, index) => `Été ${index} : ${'la forêt s’endort doucement. '.repeat(8)}`.trim());
  const text = paragraphs.join('\n\n');
  const chunks = speechChunks(text);
  assert.ok(chunks.length > 1);
  assert.ok(chunks.every((chunk) => new TextEncoder().encode(chunk).length <= 4800));
  assert.equal(chunks.join('\n\n'), text);
});

Deno.test('paragraphe trop long : coupé entre deux mots', () => {
  const paragraph = 'éléphant '.repeat(800).trim();
  const chunks = speechChunks(paragraph);
  assert.ok(chunks.every((chunk) => new TextEncoder().encode(chunk).length <= 4800));
  assert.equal(chunks.join(' '), paragraph);
});
