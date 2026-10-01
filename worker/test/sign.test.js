import assert from 'node:assert/strict';
import { test } from 'node:test';
import { SignJWT, createLocalJWKSet, exportJWK, generateKeyPair } from 'jose';

import { verifyFirebaseToken } from '../src/auth.js';
import { handle } from '../src/index.js';
import { cloudinarySignature, parseSignRequest, publicIdFor } from '../src/sign.js';

const ID_A = 'A'.repeat(20);
const ID_B = 'b1'.repeat(10);
const env = {
  FIREBASE_PROJECT_ID: 'demo-proj',
  CLOUDINARY_CLOUD_NAME: 'demo-cloud',
  CLOUDINARY_API_KEY: '1234',
  CLOUDINARY_API_SECRET: 'abcd',
  FOLDER: 'tanktrail-test',
};

test('signature matches the example in Cloudinary docs', async () => {
  const sig = await cloudinarySignature(
    { eager: 'w_400,h_300,c_pad|w_260,h_200,c_crop', public_id: 'sample_image', timestamp: '1315060510', api_key: 'x', file: 'y' },
    'abcd',
  );
  assert.equal(sig, 'bfd09f95f331f558cbd1320e67aa8d488770583e');
});

test('request validation', () => {
  assert.deepEqual(parseSignRequest({ items: [{ logId: ID_A, mediaId: ID_B, kind: 'video' }] }), [
    { logId: ID_A, mediaId: ID_B, kind: 'video' },
  ]);
  assert.throws(() => parseSignRequest({ items: [] }));
  assert.throws(() => parseSignRequest({ items: [{ logId: '../x', mediaId: ID_B, kind: 'image' }] }));
  assert.throws(() => parseSignRequest({ items: [{ logId: ID_A, mediaId: ID_B, kind: 'raw' }] }));
  assert.throws(() => parseSignRequest({ items: Array(11).fill({ logId: ID_A, mediaId: ID_B, kind: 'image' }) }));
  assert.equal(publicIdFor('f', 'uid1', { logId: ID_A, mediaId: ID_B }), `f/uid1/${ID_A}/${ID_B}`);
});

// A fake Google key pair, so token checks run without the network.
async function tokenFactory() {
  const { publicKey, privateKey } = await generateKeyPair('RS256');
  const jwk = { ...(await exportJWK(publicKey)), kid: 'k1', alg: 'RS256' };
  const keys = createLocalJWKSet({ keys: [jwk] });
  const now = Math.floor(Date.now() / 1000);
  const make = (claims = {}, { aud = env.FIREBASE_PROJECT_ID, exp = now + 3600 } = {}) =>
    new SignJWT({ auth_time: now - 10, ...claims })
      .setProtectedHeader({ alg: 'RS256', kid: 'k1' })
      .setIssuer(`https://securetoken.google.com/${aud}`)
      .setAudience(aud)
      .setSubject('uid-ali')
      .setIssuedAt(now - 10)
      .setExpirationTime(exp)
      .sign(privateKey);
  return { keys, make, now };
}

test('token verification: valid, wrong project, expired', async () => {
  const { keys, make, now } = await tokenFactory();
  const payload = await verifyFirebaseToken(await make({ role: 'driver' }), env.FIREBASE_PROJECT_ID, keys);
  assert.equal(payload.sub, 'uid-ali');
  await assert.rejects(verifyFirebaseToken(await make({}, { aud: 'other' }), env.FIREBASE_PROJECT_ID, keys));
  await assert.rejects(verifyFirebaseToken(await make({}, { exp: now - 100 }), env.FIREBASE_PROJECT_ID, keys));
});

test('handler: driver gets signed fields, others are refused', async () => {
  const { keys, make } = await tokenFactory();
  const verify = (t, p) => verifyFirebaseToken(t, p, keys);
  const req = (token, body = { items: [{ logId: ID_A, mediaId: ID_B, kind: 'image' }] }) =>
    new Request('https://w.example/sign', {
      method: 'POST',
      headers: { authorization: `Bearer ${token}` },
      body: JSON.stringify(body),
    });

  const ok = await handle(req(await make({ role: 'driver' })), env, verify);
  assert.equal(ok.status, 200);
  const { items } = await ok.json();
  assert.equal(items[0].uploadUrl, 'https://api.cloudinary.com/v1_1/demo-cloud/image/upload');
  assert.equal(items[0].fields.public_id, `tanktrail-test/uid-ali/${ID_A}/${ID_B}`);
  assert.equal(items[0].fields.overwrite, 'false');
  assert.equal(items[0].fields.api_key, '1234');
  assert.equal('api_secret' in items[0].fields, false);
  const expected = await cloudinarySignature(
    { overwrite: 'false', public_id: items[0].fields.public_id, timestamp: items[0].fields.timestamp },
    'abcd',
  );
  assert.equal(items[0].fields.signature, expected);

  assert.equal((await handle(req(await make({ role: 'admin' })), env, verify)).status, 403);
  assert.equal((await handle(req(await make({})), env, verify)).status, 403);
  assert.equal((await handle(req('garbage'), env, verify)).status, 401);
  assert.equal((await handle(req(await make({ role: 'driver' }), { items: [] }), env, verify)).status, 400);
  assert.equal((await handle(req(await make({ role: 'driver' })), { ...env, CLOUDINARY_API_SECRET: '' }, verify)).status, 500);
});
