// Pure helpers: request validation and Cloudinary signatures. No I/O here, so
// they are unit-tested in test/sign.test.js.

const ID = /^[A-Za-z0-9]{20}$/; // app-generated IDs (same shape as Firestore auto-IDs)
const KINDS = new Set(['image', 'video']);
export const MAX_ITEMS = 10;

/** Validates {items:[{logId, mediaId, kind}]}. Returns the items or throws. */
export function parseSignRequest(body) {
  const items = body?.items;
  if (!Array.isArray(items) || items.length === 0 || items.length > MAX_ITEMS) {
    throw new Error(`items must be a list of 1..${MAX_ITEMS}`);
  }
  return items.map((it) => {
    if (!ID.test(it?.logId ?? '') || !ID.test(it?.mediaId ?? '')) throw new Error('bad id');
    if (!KINDS.has(it.kind)) throw new Error('bad kind');
    return { logId: it.logId, mediaId: it.mediaId, kind: it.kind };
  });
}

/**
 * The Worker, not the phone, decides where a file goes. The uid in the path
 * keeps drivers apart; overwrite=false (signed) means existing evidence can
 * never be replaced, and a repeated upload just returns the existing file.
 */
export function publicIdFor(folder, uid, item) {
  return `${folder}/${uid}/${item.logId}/${item.mediaId}`;
}

/**
 * Cloudinary signature: all signed params except file, cloud_name,
 * resource_type and api_key, sorted by name, joined as a=b&c=d, then the API
 * secret appended, SHA-1 hex. (cloudinary.com/documentation/authentication_signatures)
 */
export async function cloudinarySignature(params, apiSecret) {
  const toSign = Object.keys(params)
    .filter((k) => !['file', 'cloud_name', 'resource_type', 'api_key'].includes(k))
    .sort()
    .map((k) => `${k}=${params[k]}`)
    .join('&');
  const bytes = new TextEncoder().encode(toSign + apiSecret);
  const digest = await crypto.subtle.digest('SHA-1', bytes);
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

/** Signed upload instructions for one file. */
export async function signItem({ item, uid, env, nowSec }) {
  const params = {
    overwrite: 'false',
    public_id: publicIdFor(env.FOLDER, uid, item),
    timestamp: String(nowSec),
  };
  return {
    mediaId: item.mediaId,
    uploadUrl: `https://api.cloudinary.com/v1_1/${env.CLOUDINARY_CLOUD_NAME}/${item.kind}/upload`,
    fields: { ...params, api_key: env.CLOUDINARY_API_KEY, signature: await cloudinarySignature(params, env.CLOUDINARY_API_SECRET) },
  };
}
