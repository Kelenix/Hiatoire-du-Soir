// Reçoit les événements d'achat de RevenueCat (docs/system-design.md §2.5, ADR-009).
// RevenueCat n'envoie pas de jeton Supabase : l'appel est authentifié par un secret partagé,
// configuré dans RevenueCat comme en-tête « Authorization: Bearer <secret> ».
import { timingSafeEqual } from 'node:crypto';

import { createClient } from 'npm:@supabase/supabase-js@2.119.0';

const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
const secret = Deno.env.get('REVENUECAT_WEBHOOK_SECRET');
const expected = new TextEncoder().encode(`Bearer ${secret}`);

/** Comparaison en temps constant : la durée de la réponse ne renseigne pas sur le secret. */
function isAuthorized(header: string | null) {
  const given = new TextEncoder().encode(header ?? '');
  return Boolean(secret) && given.length === expected.length && timingSafeEqual(given, expected);
}

Deno.serve(async (request) => {
  if (!isAuthorized(request.headers.get('Authorization'))) {
    return Response.json({ error: 'UNAUTHORIZED' }, { status: 401 });
  }
  const event = (await request.json().catch(() => null))?.event;
  if (typeof event?.id !== 'string' || typeof event?.type !== 'string') {
    return Response.json({ error: 'INVALID_INPUT' }, { status: 400 });
  }

  const { error } = await supabase.rpc('apply_purchase_event', { p_event: event });
  if (error) {
    // Réponse en erreur : RevenueCat renverra l'événement plus tard.
    console.error('Événement d’achat non appliqué', event.type, error.message);
    return Response.json({ error: 'UPSTREAM_ERROR' }, { status: 500 });
  }
  return Response.json({ received: true });
});
