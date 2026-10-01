// TankTrail upload signer (Cloudflare Worker, free plan).
// POST /sign  Authorization: Bearer <Firebase ID token>
//   body {items: [{logId, mediaId, kind: 'image'|'video'}]}
// -> {items: [{mediaId, uploadUrl, fields}]}
// The Cloudinary API secret lives only here (wrangler secret).
import { verifyFirebaseToken } from './auth.js';
import { parseSignRequest, signItem } from './sign.js';

const json = (status, body) =>
  new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json' } });

export async function handle(request, env, verify = verifyFirebaseToken) {
  const url = new URL(request.url);
  if (url.pathname !== '/sign') return json(404, { error: 'not found' });
  if (request.method !== 'POST') return json(405, { error: 'POST only' });
  if (!env.CLOUDINARY_API_SECRET || !env.CLOUDINARY_API_KEY || env.CLOUDINARY_CLOUD_NAME === 'SET_ME') {
    return json(500, { error: 'signer not configured' });
  }

  const token = (request.headers.get('authorization') ?? '').replace(/^Bearer /, '');
  let user;
  try {
    user = await verify(token, env.FIREBASE_PROJECT_ID);
  } catch {
    return json(401, { error: 'invalid token' });
  }
  // Only drivers capture evidence. Same role claim the Firestore rules use.
  if (user.role !== 'driver') return json(403, { error: 'drivers only' });

  let items;
  try {
    items = parseSignRequest(await request.json());
  } catch (e) {
    return json(400, { error: String(e.message ?? e) });
  }

  const nowSec = Math.floor(Date.now() / 1000);
  const signed = await Promise.all(items.map((item) => signItem({ item, uid: user.sub, env, nowSec })));
  return json(200, { items: signed });
}

export default {
  fetch: (request, env) => handle(request, env),
};
