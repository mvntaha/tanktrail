// Creates and updates TankTrail accounts from drivers.local.json (Admin SDK, bypasses rules).
//
//   node seed.js --project <projectId>                  create/update every account
//   node seed.js --project <projectId> --reset <email>  give one account a new random password
//
// GOOGLE_APPLICATION_CREDENTIALS must point at the service-account key, kept OUTSIDE the repo.
// --project must match the key's project, so dev and prod can't be mixed up by accident.
// Accounts are never deleted: removing someone = "active": false.
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { randomInt } from 'node:crypto';
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

const DRIVERS_FILE = new URL('./drivers.local.json', import.meta.url);
const CREDENTIALS_FILE = new URL('./credentials.local.json', import.meta.url);
const MIN_PASSWORD = 8;

function fail(msg) {
  console.error(`\nERROR: ${msg}`);
  process.exit(1);
}

function arg(name) {
  const i = process.argv.indexOf(name);
  return i === -1 ? undefined : process.argv[i + 1];
}

// Readable random password without look-alike characters (0/O, 1/l/I).
function generatePassword(length = 12) {
  const chars = 'abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let out = '';
  for (let i = 0; i < length; i++) out += chars[randomInt(chars.length)];
  return out;
}

// Appends new passwords so the owner can hand them to drivers privately.
function recordPassword(email, password, reason) {
  const list = existsSync(CREDENTIALS_FILE) ? JSON.parse(readFileSync(CREDENTIALS_FILE, 'utf8')) : [];
  list.push({ email, password, reason, at: new Date().toISOString() });
  writeFileSync(CREDENTIALS_FILE, JSON.stringify(list, null, 2) + '\n');
}

function checkProject() {
  const project = arg('--project');
  if (!project) fail('Pass --project <projectId>, e.g. --project tanktrail-dev-e514e');
  const keyPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (!keyPath || !existsSync(keyPath)) {
    fail('Set $env:GOOGLE_APPLICATION_CREDENTIALS to the service-account key path (outside the repo).');
  }
  const keyProject = JSON.parse(readFileSync(keyPath, 'utf8')).project_id;
  if (keyProject !== project) fail(`Key belongs to "${keyProject}" but --project is "${project}".`);
  return project;
}

function loadAccounts() {
  if (!existsSync(DRIVERS_FILE)) fail('backend/drivers.local.json not found. Copy drivers.example.json and fill it in.');
  const file = JSON.parse(readFileSync(DRIVERS_FILE, 'utf8'));
  if (!file.admin || Array.isArray(file.admin)) fail('"admin" must be exactly one account object.');

  const accounts = [
    { ...file.admin, role: 'admin' },
    ...(file.drivers ?? []).map((d) => ({ ...d, role: 'driver' })),
  ].map((a) => ({ ...a, email: String(a.email ?? '').trim().toLowerCase(), active: a.active !== false }));

  const seen = new Set();
  for (const a of accounts) {
    if (!a.name || !String(a.name).trim()) fail(`Missing name for ${a.email || 'an account'}.`);
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(a.email)) fail(`Invalid email: "${a.email}".`);
    if (a.email.endsWith('@example.com')) fail(`${a.email} is a placeholder. Use real emails.`);
    if (seen.has(a.email)) fail(`Duplicate email ${a.email} (the admin and your driver account must differ).`);
    if (a.password !== undefined && String(a.password).length < MIN_PASSWORD) {
      fail(`Password for ${a.email} must be at least ${MIN_PASSWORD} characters.`);
    }
    seen.add(a.email);
  }
  return accounts;
}

async function listAllUsers(auth) {
  const users = [];
  let pageToken;
  do {
    const page = await auth.listUsers(1000, pageToken);
    users.push(...page.users);
    pageToken = page.pageToken;
  } while (pageToken);
  return users;
}

async function findUser(auth, email) {
  try {
    return await auth.getUserByEmail(email);
  } catch (e) {
    if (e.code === 'auth/user-not-found') return null;
    throw e;
  }
}

async function syncAccount(auth, db, a) {
  let user = await findUser(auth, a.email);
  let action;

  if (!user) {
    const password = a.password ?? generatePassword();
    user = await auth.createUser({ email: a.email, password, displayName: a.name, disabled: !a.active });
    if (a.password === undefined) recordPassword(a.email, password, 'created');
    action = 'created';
  } else {
    if (a.password !== undefined) {
      console.warn(`  note: password for existing ${a.email} ignored (use --reset to change it)`);
    }
    await auth.updateUser(user.uid, { displayName: a.name, disabled: !a.active });
    action = 'updated';
  }

  // Keep other claims, set role. Takes effect at the user's next login / token refresh.
  const claims = user.customClaims ?? {};
  if (claims.role !== a.role) {
    await auth.setCustomUserClaims(user.uid, { ...claims, role: a.role });
    action += `, role -> ${a.role}`;
  }
  if (!a.active) await auth.revokeRefreshTokens(user.uid);

  // merge: keeps locationNoticeAcceptedAt written by the app.
  await db.doc(`users/${user.uid}`).set(
    { name: a.name, email: a.email, role: a.role, active: a.active },
    { merge: true },
  );
  console.log(`  ${a.role.padEnd(6)} ${a.active ? 'active  ' : 'DISABLED'} ${a.email} (${action})`);
}

async function main() {
  const project = checkProject();
  initializeApp({ credential: applicationDefault(), projectId: project });
  const auth = getAuth();
  const db = getFirestore();

  const resetEmail = arg('--reset');
  if (resetEmail) {
    const user = await findUser(auth, resetEmail.trim().toLowerCase());
    if (!user) fail(`No account for ${resetEmail}.`);
    const password = generatePassword();
    await auth.updateUser(user.uid, { password });
    await auth.revokeRefreshTokens(user.uid); // signs them out everywhere
    recordPassword(user.email, password, 'reset');
    console.log(`New password for ${user.email} written to backend/credentials.local.json`);
    return;
  }

  const accounts = loadAccounts();
  const listed = new Set(accounts.map((a) => a.email));
  const adminEmail = accounts.find((a) => a.role === 'admin').email;

  // Exactly one admin: refuse if some other account still holds the admin role.
  const existing = await listAllUsers(auth);
  const strayAdmins = existing.filter(
    (u) => u.customClaims?.role === 'admin' && u.email !== adminEmail && !listed.has(u.email),
  );
  if (strayAdmins.length) {
    fail(`Other admin account(s) exist: ${strayAdmins.map((u) => u.email).join(', ')}. ` +
      'Add them to drivers.local.json as drivers (or active:false) first.');
  }

  console.log(`Seeding project ${project}:`);
  for (const a of accounts) await syncAccount(auth, db, a);

  for (const u of existing) {
    if (!listed.has(u.email)) console.warn(`  note: ${u.email} is not in drivers.local.json; left unchanged`);
  }
  if (existsSync(CREDENTIALS_FILE)) {
    console.log('\nGenerated passwords are in backend/credentials.local.json. Hand them over privately.');
  }
  console.log('Role changes apply after each user signs out and in again.');
}

main().catch((e) => fail(e.message ?? String(e)));
