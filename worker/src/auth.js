import { createRemoteJWKSet, jwtVerify } from 'jose';

// Google's public keys for Firebase ID tokens (JWK form of the x509 list in
// firebase.google.com/docs/auth/admin/verify-id-tokens). jose caches them.
const GOOGLE_JWKS = createRemoteJWKSet(
  new URL('https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com'),
);

/**
 * Verifies a Firebase ID token per Firebase's checklist: RS256, known kid,
 * exp in the future, iat/auth_time in the past, aud = project ID,
 * iss = securetoken.google.com/<project>, non-empty sub.
 * [keys] is injectable for tests. Returns the token payload or throws.
 */
export async function verifyFirebaseToken(token, projectId, keys = GOOGLE_JWKS) {
  const { payload } = await jwtVerify(token, keys, {
    algorithms: ['RS256'],
    audience: projectId,
    issuer: `https://securetoken.google.com/${projectId}`,
    clockTolerance: 30,
  });
  const now = Math.floor(Date.now() / 1000);
  if (typeof payload.sub !== 'string' || payload.sub === '') throw new Error('no sub');
  if (typeof payload.iat !== 'number' || payload.iat > now + 30) throw new Error('bad iat');
  if (typeof payload.auth_time !== 'number' || payload.auth_time > now + 30) throw new Error('bad auth_time');
  return payload;
}
