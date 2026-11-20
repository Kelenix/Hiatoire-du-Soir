// Réponses communes aux fonctions : un code d'erreur que l'app sait traduire (lib/core/failure.dart).
import type { SupabaseClient, User } from 'npm:@supabase/supabase-js@2.119.0';

const statusByError = {
  INVALID_INPUT: 400,
  UNAUTHORIZED: 401,
  LOCKED: 403,
  QUOTA_REACHED: 403,
  BUSY: 409,
  CONTENT_REJECTED: 422,
  ABUSE_LIMIT: 429,
  UPSTREAM_ERROR: 502,
} as const;
export type ErrorCode = keyof typeof statusByError;

export const fail = (code: ErrorCode) => Response.json({ error: code }, { status: statusByError[code] });

/** Les fonctions SQL lèvent des codes connus (QUOTA_REACHED, LOCKED…) ; le reste est inattendu. */
export function failFromDatabase(error: { message: string }) {
  if (Object.hasOwn(statusByError, error.message)) return fail(error.message as ErrorCode);
  console.error('Erreur base de données', error.message);
  return fail('UPSTREAM_ERROR');
}

/** Utilisateur de la session Supabase envoyée par l'app, ou null. */
export async function requestUser(supabase: SupabaseClient, request: Request): Promise<User | null> {
  const token = request.headers.get('Authorization')?.replace(/^Bearer /, '');
  return (await supabase.auth.getUser(token)).data.user;
}
