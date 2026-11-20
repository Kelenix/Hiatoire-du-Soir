// Charge du backend Supabase utilisé par l'app (docs/qa/load-report.md), sur le Supabase LOCAL
// uniquement. Aucune histoire n'est écrite : les créations sont refusées faute de quota, ce qui fait
// passer la fonction et ses contrôles sans appeler Claude (aucun coût).
//
// Profils : PROFILE=smoke | load | stress. Lancement (Docker) : voir docs/qa/load-report.md.
import { check, sleep } from 'k6';
import http from 'k6/http';

const BASE = __ENV.SUPABASE_URL || 'http://host.docker.internal:59321';
const ANON = __ENV.ANON_KEY;
const SERVICE = __ENV.SERVICE_ROLE_KEY;
const USERS = 8; // sous la limite locale de 30 connexions par 5 minutes

const profiles = {
  smoke: { vus: 1, duration: '30s' },
  load: { stages: [{ duration: '30s', target: 20 }, { duration: '1m', target: 20 }, { duration: '30s', target: 0 }] },
  stress: { stages: [{ duration: '30s', target: 20 }, { duration: '1m', target: 50 }, { duration: '30s', target: 0 }] },
};

export const options = {
  ...profiles[__ENV.PROFILE || 'smoke'],
  thresholds: {
    'http_req_failed{type:lecture}': ['rate<0.01'],
    'http_req_duration{type:lecture}': ['p(95)<500'],
    'http_req_failed{type:creation}': ['rate<0.01'],
    'http_req_duration{type:creation}': ['p(95)<1500'],
    checks: ['rate>0.99'],
  },
};

const json = (key, token = key) => ({
  headers: { apikey: key, Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
});

const uuid = () =>
  'xxxxxxxx-xxxx-4xxx-8xxx-xxxxxxxxxxxx'.replace(/x/g, () => Math.floor(Math.random() * 16).toString(16));

/** Familles d'essai jetables, quota gratuit déjà utilisé ; supprimées à la fin. */
export function setup() {
  const run = uuid().slice(0, 8);
  const users = [];
  for (let i = 1; i <= USERS; i++) {
    const credentials = { email: `charge-${run}-${i}@test.local`, password: uuid() };
    const created = http.post(`${BASE}/auth/v1/admin/users`, JSON.stringify({ ...credentials, email_confirm: true }), json(SERVICE));
    const session = http.post(`${BASE}/auth/v1/token?grant_type=password`, JSON.stringify(credentials), json(ANON));
    users.push({ id: created.json('id'), token: session.json('access_token') });
  }
  const used = users.flatMap((user) =>
    [1, 2, 3].map(() => ({ user_id: user.id, request_id: uuid(), source: 'free', theme_id: 'animaux', duration_min: 2 })),
  );
  http.post(`${BASE}/rest/v1/generations`, JSON.stringify(used), json(SERVICE));
  // Démarrage à froid de la fonction, hors mesures (les seuils ne portent que sur les requêtes typées).
  http.post(`${BASE}/functions/v1/generate-story`, JSON.stringify({ request_id: uuid(), theme_id: 'animaux', duration_min: 2 }), {
    ...json(ANON, users[0].token),
    responseCallback: http.expectedStatuses(403, 409),
  });
  return { users };
}

export default function ({ users }) {
  const user = users[(__VU - 1) % users.length];
  const asUser = { ...json(ANON, user.token), tags: { type: 'lecture' } };

  // Ce que l'app lit à l'ouverture : droits, thèmes, dernière histoire, voix.
  const reads = http.batch([
    ['POST', `${BASE}/rest/v1/rpc/my_entitlements`, '{}', asUser],
    ['GET', `${BASE}/rest/v1/themes?select=id,name,tier,illustration&order=sort_order`, null, asUser],
    ['GET', `${BASE}/rest/v1/stories?select=*&order=created_at.desc&limit=1`, null, asUser],
    ['GET', `${BASE}/rest/v1/voices?select=id,name,description&order=sort_order`, null, asUser],
  ]);
  check(reads, { 'lectures : 200': (responses) => responses.every((response) => response.status === 200) });

  if (__ITER % 5 === 0) {
    const creation = http.post(
      `${BASE}/functions/v1/generate-story`,
      JSON.stringify({ request_id: uuid(), theme_id: 'animaux', duration_min: 2 }),
      { ...json(ANON, user.token), tags: { type: 'creation' }, responseCallback: http.expectedStatuses(403, 409) },
    );
    check(creation, { 'création refusée sans appel à Claude': (response) => [403, 409].includes(response.status) });
  }
  sleep(1);
}

export function teardown({ users }) {
  for (const user of users) http.del(`${BASE}/auth/v1/admin/users/${user.id}`, null, json(SERVICE));
}
