// Rules tests. Run from backend/:  npm run test:rules
// Uses a "demo-" project ID so the emulator never touches a real Firebase project.
import { readFileSync } from 'node:fs';
import {
  initializeTestEnvironment, assertSucceeds, assertFails,
} from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, updateDoc, deleteDoc, writeBatch, serverTimestamp, Timestamp,
} from 'firebase/firestore';

const ALI = 'driverAli';
const BILAL = 'driverBilal';
const GONE = 'driverInactive';
const ADMIN = 'admin1';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-tanktrail',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
});

after(async () => { await env.cleanup(); });

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users', ALI), { name: 'Ali', email: 'ali@example.com', role: 'driver', active: true });
    await setDoc(doc(db, 'users', BILAL), { name: 'Bilal', email: 'bilal@example.com', role: 'driver', active: true });
    await setDoc(doc(db, 'users', GONE), { name: 'Old', email: 'old@example.com', role: 'driver', active: false });
    await setDoc(doc(db, 'users', ADMIN), { name: 'Admin', email: 'admin@example.com', role: 'admin', active: true });
  });
});

// ---------- contexts ----------
const driver = (uid = ALI) => env.authenticatedContext(uid, { role: 'driver' }).firestore();
const admin = () => env.authenticatedContext(ADMIN, { role: 'admin' }).firestore();
const noRole = () => env.authenticatedContext('someone').firestore();
const badRole = () => env.authenticatedContext('someone', { role: 'superuser' }).firestore();
const anon = () => env.unauthenticatedContext().firestore();

// ---------- sample data ----------
const loc = () => ({ lat: 24.86, lng: 67.0, acc: 12, mock: false });
const media = (type, extra = {}) => ({
  type, url: 'https://res.cloudinary.com/demo/x', publicId: 'x', sha256: 'ab12',
  capturedAtDevice: Timestamp.now(), ...extra,
});

const tripStart = (over = {}) => ({
  driverId: ALI, driverName: 'Ali', startOdo: 1000, startedAt: Timestamp.now(),
  startEvidence: [media('odometer')], createdAt: serverTimestamp(), status: 'open', edited: false,
  ...over,
});
const tripStartGeo = () => ({ startLoc: loc(), startEvidenceLocs: [loc()] });

function startTrip(db, { id = 't1', data = tripStart(), geo = tripStartGeo() } = {}) {
  const b = writeBatch(db);
  b.set(doc(db, 'trips', id), data);
  if (geo) b.set(doc(db, 'trips', id, 'private', 'geo'), geo);
  return b.commit();
}

function closeTrip(db, { id = 't1', over = {}, geo = { endLoc: loc(), endEvidenceLocs: [loc()] } } = {}) {
  const b = writeBatch(db);
  b.update(doc(db, 'trips', id), {
    status: 'closed', endOdo: 1050, endedAt: Timestamp.now(),
    endEvidence: [media('odometer')], closedAt: serverTimestamp(), ...over,
  });
  if (geo) b.update(doc(db, 'trips', id, 'private', 'geo'), geo);
  return b.commit();
}

const fill = (over = {}) => ({
  driverId: ALI, driverName: 'Ali', odometer: 1200, liters: 10, pricePerL: 280, total: 2800,
  fuelType: 'petrol', paidBy: 'company_cash',
  evidence: [media('odometer'), media('pump'), media('video', { durationSec: 30 })],
  capturedAtDevice: Timestamp.now(), createdAt: serverTimestamp(), status: 'pending', edited: false,
  ...over,
});
const fillGeo = () => ({ loc: loc(), evidenceLocs: [loc(), loc(), loc()] });
const fillPrev = { odometer: 1200, liters: 10, pricePerL: 280, total: 2800, fuelType: 'petrol', paidBy: 'company_cash' };

function createFill(db, { id = 'f1', data = fill(), geo = fillGeo() } = {}) {
  const b = writeBatch(db);
  b.set(doc(db, 'fuelLogs', id), data);
  if (geo) b.set(doc(db, 'fuelLogs', id, 'private', 'geo'), geo);
  return b.commit();
}

// A driver edit: update the log + write its history entry in one batch.
function editLog(db, coll, id, changes, previous, { editId = 'e1', history = true, editedBy = ALI } = {}) {
  const b = writeBatch(db);
  b.update(doc(db, coll, id), { ...changes, edited: true, editedAt: serverTimestamp(), lastEditId: editId });
  if (history) {
    b.set(doc(db, coll, id, 'edits', editId), { previous, editedAt: serverTimestamp(), editedBy });
  }
  return b.commit();
}

// =====================================================================
describe('roles', () => {
  it('unauthenticated users can read nothing', async () => {
    await assertFails(getDoc(doc(anon(), 'trips', 't1')));
    await assertFails(getDoc(doc(anon(), 'vehicle', 'main')));
  });
  it('signed-in user without a role claim is rejected', async () => {
    await assertFails(getDoc(doc(noRole(), 'trips', 't1')));
    await assertFails(getDoc(doc(noRole(), 'fuelLogs', 'f1')));
    await assertFails(startTrip(noRole(), { data: tripStart({ driverId: 'someone' }) }));
  });
  it('an unknown role value is rejected', async () => {
    await assertFails(getDoc(doc(badRole(), 'trips', 't1')));
  });
});

// =====================================================================
describe('users', () => {
  it('driver reads own doc but not others', async () => {
    await assertSucceeds(getDoc(doc(driver(), 'users', ALI)));
    await assertFails(getDoc(doc(driver(), 'users', BILAL)));
  });
  it('admin reads any user doc', async () => {
    await assertSucceeds(getDoc(doc(admin(), 'users', ALI)));
  });
  it('driver can accept the location notice once, with server time', async () => {
    await assertSucceeds(updateDoc(doc(driver(), 'users', ALI), { locationNoticeAcceptedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(driver(), 'users', ALI), { locationNoticeAcceptedAt: serverTimestamp() }));
  });
  it('notice with a device timestamp is denied', async () => {
    await assertFails(updateDoc(doc(driver(), 'users', ALI), { locationNoticeAcceptedAt: Timestamp.now() }));
  });
  it('driver cannot change their role, name or active flag', async () => {
    await assertFails(updateDoc(doc(driver(), 'users', ALI), { role: 'admin' }));
    await assertFails(updateDoc(doc(driver(), 'users', ALI), { name: 'X' }));
    await assertFails(updateDoc(doc(driver(), 'users', ALI), { active: false, locationNoticeAcceptedAt: serverTimestamp() }));
  });
  it('driver cannot write another user doc; nobody creates users from the app', async () => {
    await assertFails(updateDoc(doc(driver(), 'users', BILAL), { locationNoticeAcceptedAt: serverTimestamp() }));
    await assertFails(setDoc(doc(driver(), 'users', 'newUser'), { name: 'N', role: 'driver' }));
    await assertFails(setDoc(doc(admin(), 'users', 'newUser'), { name: 'N', role: 'driver' }));
  });
});

// =====================================================================
describe('vehicle', () => {
  const vehicle = { name: 'Alto', plate: 'ABC-123', fuelType: 'petrol' };
  it('admin writes vehicle/main; everyone with a role reads it', async () => {
    await assertSucceeds(setDoc(doc(admin(), 'vehicle', 'main'), vehicle));
    await assertSucceeds(updateDoc(doc(admin(), 'vehicle', 'main'), { baselineKmPerL: 15 }));
    await assertSucceeds(getDoc(doc(driver(), 'vehicle', 'main')));
  });
  it('driver cannot write the vehicle', async () => {
    await assertFails(setDoc(doc(driver(), 'vehicle', 'main'), vehicle));
  });
  it('unknown fields or other doc IDs are denied', async () => {
    await assertFails(setDoc(doc(admin(), 'vehicle', 'main'), { ...vehicle, color: 'red' }));
    await assertFails(setDoc(doc(admin(), 'vehicle', 'other'), vehicle));
    await assertFails(setDoc(doc(admin(), 'vehicle', 'main'), { ...vehicle, baselineKmPerL: 'fifteen' }));
  });
});

// =====================================================================
describe('places', () => {
  const place = { name: 'Home', lat: 24.9, lng: 67.1, radiusM: 150 };
  it('admin reads and writes places', async () => {
    await assertSucceeds(setDoc(doc(admin(), 'places', 'p1'), place));
    await assertSucceeds(getDoc(doc(admin(), 'places', 'p1')));
  });
  it('driver cannot read or write places', async () => {
    await assertFails(getDoc(doc(driver(), 'places', 'p1')));
    await assertFails(setDoc(doc(driver(), 'places', 'p1'), place));
  });
  it('invalid place is denied', async () => {
    await assertFails(setDoc(doc(admin(), 'places', 'p1'), { ...place, radiusM: 0 }));
    await assertFails(setDoc(doc(admin(), 'places', 'p1'), { ...place, extra: 1 }));
  });
});

// =====================================================================
describe('trips: start', () => {
  it('driver starts own trip with geo in the same batch', async () => {
    await assertSucceeds(startTrip(driver()));
  });
  it('every driver can read every trip', async () => {
    await startTrip(driver());
    await assertSucceeds(getDoc(doc(driver(BILAL), 'trips', 't1')));
  });
  it('start without private/geo is denied', async () => {
    await assertFails(startTrip(driver(), { geo: null }));
  });
  it('trip for another driver or with a wrong name is denied', async () => {
    await assertFails(startTrip(driver(BILAL)));
    await assertFails(startTrip(driver(), { data: tripStart({ driverName: 'Bilal' }) }));
  });
  it('device-time createdAt, non-open status or missing photo is denied', async () => {
    await assertFails(startTrip(driver(), { data: tripStart({ createdAt: Timestamp.now() }) }));
    await assertFails(startTrip(driver(), { data: tripStart({ status: 'closed' }) }));
    await assertFails(startTrip(driver(), { data: tripStart({ startEvidence: [] }) }));
    await assertFails(startTrip(driver(), { data: tripStart({ edited: true }) }));
  });
  it('extra fields such as reviewed are denied', async () => {
    await assertFails(startTrip(driver(), { data: tripStart({ reviewed: true }) }));
  });
  it('inactive driver and admin cannot start trips', async () => {
    await assertFails(startTrip(driver(GONE), { data: tripStart({ driverId: GONE, driverName: 'Old' }) }));
    await assertFails(startTrip(admin(), { data: tripStart({ driverId: ADMIN, driverName: 'Admin' }) }));
  });
  it('coordinates in the public trip doc are denied', async () => {
    await assertFails(startTrip(driver(), { data: tripStart({ startLoc: loc() }) }));
  });
  it('odometer order is never checked: a lower reading than before still succeeds', async () => {
    await startTrip(driver(), { id: 't1', data: tripStart({ startOdo: 5000 }) });
    await assertSucceeds(startTrip(driver(), { id: 't2', data: tripStart({ startOdo: 10 }) }));
  });
});

describe('trips: close', () => {
  beforeEach(async () => { await startTrip(driver()); });

  it('owner closes the trip with endLoc in the same batch', async () => {
    await assertSucceeds(closeTrip(driver()));
  });
  it('close without endLoc in geo is denied', async () => {
    await assertFails(closeTrip(driver(), { geo: null }));
  });
  it('another driver cannot close it', async () => {
    await assertFails(closeTrip(driver(BILAL)));
  });
  it('device-time closedAt or missing end photo is denied', async () => {
    await assertFails(closeTrip(driver(), { over: { closedAt: Timestamp.now() } }));
    await assertFails(closeTrip(driver(), { over: { endEvidence: [] } }));
  });
  it('a closed trip cannot be closed again', async () => {
    await closeTrip(driver());
    await assertFails(closeTrip(driver(), { over: { endOdo: 1100 } }));
  });
  it('closing cannot also change startOdo or evidence', async () => {
    await assertFails(closeTrip(driver(), { over: { startOdo: 1 } }));
    await assertFails(closeTrip(driver(), { over: { startEvidence: [] } }));
  });
});

describe('trips: private/geo', () => {
  beforeEach(async () => { await startTrip(driver()); });

  it('driver cannot read geo, not even their own', async () => {
    await assertFails(getDoc(doc(driver(), 'trips', 't1', 'private', 'geo')));
    await assertFails(getDoc(doc(driver(BILAL), 'trips', 't1', 'private', 'geo')));
  });
  it('admin reads geo', async () => {
    await assertSucceeds(getDoc(doc(admin(), 'trips', 't1', 'private', 'geo')));
  });
  it('geo cannot be written on its own after the trip exists', async () => {
    await assertFails(setDoc(doc(driver(), 'trips', 't1', 'private', 'geo'), tripStartGeo()));
    await assertFails(updateDoc(doc(driver(), 'trips', 't1', 'private', 'geo'), { endLoc: loc(), endEvidenceLocs: [] }));
  });
  it('geo cannot be changed after the trip is closed', async () => {
    await closeTrip(driver());
    await assertFails(updateDoc(doc(driver(), 'trips', 't1', 'private', 'geo'), { endLoc: loc(), endEvidenceLocs: [] }));
  });
  it('malformed location is denied', async () => {
    await assertFails(startTrip(driver(), { id: 't2', geo: { startLoc: { lat: 1, lng: 2 }, startEvidenceLocs: [] } }));
  });
});

describe('trips: driver edits', () => {
  beforeEach(async () => { await startTrip(driver()); });

  it('edit of an open trip with a history entry succeeds', async () => {
    await assertSucceeds(editLog(driver(), 'trips', 't1', { startOdo: 1001 }, { startOdo: 1000, endOdo: null }));
  });
  it('edit without a history entry is denied', async () => {
    await assertFails(editLog(driver(), 'trips', 't1', { startOdo: 1001 }, null, { history: false }));
  });
  it('history with wrong previous values is denied', async () => {
    await assertFails(editLog(driver(), 'trips', 't1', { startOdo: 1001 }, { startOdo: 999, endOdo: null }));
  });
  it('edit of a closed trip can fix endOdo', async () => {
    await closeTrip(driver());
    await assertSucceeds(editLog(driver(), 'trips', 't1', { endOdo: 1060 }, { startOdo: 1000, endOdo: 1050 }));
  });
  it('a second edit needs a new history id', async () => {
    await editLog(driver(), 'trips', 't1', { startOdo: 1001 }, { startOdo: 1000, endOdo: null }, { editId: 'e1' });
    await assertFails(editLog(driver(), 'trips', 't1', { startOdo: 1002 }, { startOdo: 1001, endOdo: null }, { editId: 'e1' }));
    await assertSucceeds(editLog(driver(), 'trips', 't1', { startOdo: 1002 }, { startOdo: 1001, endOdo: null }, { editId: 'e2' }));
  });
  it('evidence, timestamps, status and driver cannot be edited', async () => {
    const prev = { startOdo: 1000, endOdo: null };
    await assertFails(editLog(driver(), 'trips', 't1', { startOdo: 1001, startEvidence: [] }, prev));
    await assertFails(editLog(driver(), 'trips', 't1', { startOdo: 1001, startedAt: Timestamp.now() }, prev));
    await assertFails(editLog(driver(), 'trips', 't1', { startOdo: 1001, status: 'closed' }, prev));
    await assertFails(editLog(driver(), 'trips', 't1', { startOdo: 1001, reviewed: true }, prev));
  });
  it('another driver cannot edit', async () => {
    await assertFails(editLog(driver(BILAL), 'trips', 't1', { startOdo: 1001 },
      { startOdo: 1000, endOdo: null }, { editedBy: BILAL }));
  });
  it('a reviewed trip is locked until the admin un-reviews it', async () => {
    await updateDoc(doc(admin(), 'trips', 't1'), { reviewed: true, reviewedAt: serverTimestamp() });
    await assertFails(editLog(driver(), 'trips', 't1', { startOdo: 1001 }, { startOdo: 1000, endOdo: null }));
    await updateDoc(doc(admin(), 'trips', 't1'), { reviewed: false, reviewedAt: serverTimestamp() });
    await assertSucceeds(editLog(driver(), 'trips', 't1', { startOdo: 1001 }, { startOdo: 1000, endOdo: null }));
  });
  it('drivers cannot read edit history; admin can', async () => {
    await editLog(driver(), 'trips', 't1', { startOdo: 1001 }, { startOdo: 1000, endOdo: null });
    await assertFails(getDoc(doc(driver(), 'trips', 't1', 'edits', 'e1')));
    await assertSucceeds(getDoc(doc(admin(), 'trips', 't1', 'edits', 'e1')));
  });
});

describe('trips: admin', () => {
  beforeEach(async () => { await startTrip(driver()); });

  it('admin marks reviewed with a note', async () => {
    await assertSucceeds(updateDoc(doc(admin(), 'trips', 't1'),
      { reviewed: true, reviewedAt: serverTimestamp(), adminNote: 'ok' }));
  });
  it('changing reviewed without reviewedAt is denied', async () => {
    await assertFails(updateDoc(doc(admin(), 'trips', 't1'), { reviewed: true }));
  });
  it('admin cannot change readings or status', async () => {
    await assertFails(updateDoc(doc(admin(), 'trips', 't1'), { startOdo: 5 }));
    await assertFails(updateDoc(doc(admin(), 'trips', 't1'), { status: 'closed' }));
  });
  it('driver cannot mark reviewed', async () => {
    await assertFails(updateDoc(doc(driver(), 'trips', 't1'), { reviewed: true, reviewedAt: serverTimestamp() }));
  });
});

// =====================================================================
describe('fuelLogs: create', () => {
  it('driver creates a fill with 3 media and geo in one batch', async () => {
    await assertSucceeds(createFill(driver()));
  });
  it('every driver can read every fill', async () => {
    await createFill(driver());
    await assertSucceeds(getDoc(doc(driver(BILAL), 'fuelLogs', 'f1')));
  });
  it('fill without geo is denied', async () => {
    await assertFails(createFill(driver(), { geo: null }));
  });
  it('fewer than 3 or more than 6 media is denied', async () => {
    await assertFails(createFill(driver(), { data: fill({ evidence: [media('odometer'), media('pump')] }) }));
    await assertFails(createFill(driver(), { data: fill({ evidence: Array(7).fill(media('pump')) }) }));
  });
  it('invalid fuelType or paidBy is denied', async () => {
    await assertFails(createFill(driver(), { data: fill({ fuelType: 'jet' }) }));
    await assertFails(createFill(driver(), { data: fill({ paidBy: 'friend' }) }));
  });
  it('status other than pending, or device-time createdAt, is denied', async () => {
    await assertFails(createFill(driver(), { data: fill({ status: 'approved' }) }));
    await assertFails(createFill(driver(), { data: fill({ createdAt: Timestamp.now() }) }));
  });
  it('fill for another driver or by the admin is denied', async () => {
    await assertFails(createFill(driver(BILAL)));
    await assertFails(createFill(admin(), { data: fill({ driverId: ADMIN, driverName: 'Admin' }) }));
  });
  it('extra fields (station name, coordinates, gauge) are denied', async () => {
    await assertFails(createFill(driver(), { data: fill({ station: 'PSO' }) }));
    await assertFails(createFill(driver(), { data: fill({ loc: loc() }) }));
  });
  it('odometer order is never checked', async () => {
    await createFill(driver(), { id: 'f1', data: fill({ odometer: 9000 }) });
    await assertSucceeds(createFill(driver(), { id: 'f2', data: fill({ odometer: 5 }) }));
  });
});

describe('fuelLogs: private/geo', () => {
  beforeEach(async () => { await createFill(driver()); });

  it('driver cannot read geo; admin can', async () => {
    await assertFails(getDoc(doc(driver(), 'fuelLogs', 'f1', 'private', 'geo')));
    await assertSucceeds(getDoc(doc(admin(), 'fuelLogs', 'f1', 'private', 'geo')));
  });
  it('geo can never be changed afterwards', async () => {
    await assertFails(updateDoc(doc(driver(), 'fuelLogs', 'f1', 'private', 'geo'), { loc: loc() }));
    await assertFails(setDoc(doc(driver(), 'fuelLogs', 'f1', 'private', 'geo'), fillGeo()));
    await assertFails(updateDoc(doc(admin(), 'fuelLogs', 'f1', 'private', 'geo'), { loc: loc() }));
  });
});

describe('fuelLogs: driver edits', () => {
  beforeEach(async () => { await createFill(driver()); });

  it('pending fill edit with history succeeds', async () => {
    await assertSucceeds(editLog(driver(), 'fuelLogs', 'f1', { liters: 11, total: 3080 }, fillPrev));
  });
  it('edit without a history entry is denied', async () => {
    await assertFails(editLog(driver(), 'fuelLogs', 'f1', { liters: 11 }, null, { history: false }));
  });
  it('history with wrong previous values is denied', async () => {
    await assertFails(editLog(driver(), 'fuelLogs', 'f1', { liters: 11 }, { ...fillPrev, liters: 99 }));
  });
  it('a history entry without the log update is denied', async () => {
    await assertFails(setDoc(doc(driver(), 'fuelLogs', 'f1', 'edits', 'e9'),
      { previous: fillPrev, editedAt: serverTimestamp(), editedBy: ALI }));
  });
  it('media, capture time and status are never editable', async () => {
    await assertFails(editLog(driver(), 'fuelLogs', 'f1', { liters: 11, evidence: [] }, fillPrev));
    await assertFails(editLog(driver(), 'fuelLogs', 'f1', { liters: 11, capturedAtDevice: Timestamp.now() }, fillPrev));
    await assertFails(editLog(driver(), 'fuelLogs', 'f1', { liters: 11, status: 'approved' }, fillPrev));
  });
  it('another driver cannot edit', async () => {
    await assertFails(editLog(driver(BILAL), 'fuelLogs', 'f1', { liters: 11 }, fillPrev, { editedBy: BILAL }));
  });
  it('approved fill is locked; reopened fill is editable again', async () => {
    await updateDoc(doc(admin(), 'fuelLogs', 'f1'), { status: 'approved', reviewedAt: serverTimestamp() });
    await assertFails(editLog(driver(), 'fuelLogs', 'f1', { liters: 11 }, fillPrev));
    await updateDoc(doc(admin(), 'fuelLogs', 'f1'), { status: 'pending', reviewedAt: serverTimestamp() });
    await assertSucceeds(editLog(driver(), 'fuelLogs', 'f1', { liters: 11 }, fillPrev));
  });
});

describe('fuelLogs: admin review', () => {
  beforeEach(async () => { await createFill(driver()); });

  it('admin approves', async () => {
    await assertSucceeds(updateDoc(doc(admin(), 'fuelLogs', 'f1'), { status: 'approved', reviewedAt: serverTimestamp() }));
  });
  it('reject needs a reason', async () => {
    await assertFails(updateDoc(doc(admin(), 'fuelLogs', 'f1'), { status: 'rejected', reviewedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(admin(), 'fuelLogs', 'f1'), { status: 'rejected', reviewNote: '', reviewedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(doc(admin(), 'fuelLogs', 'f1'),
      { status: 'rejected', reviewNote: 'Pump photo unreadable', reviewedAt: serverTimestamp() }));
  });
  it('status change without server reviewedAt is denied', async () => {
    await assertFails(updateDoc(doc(admin(), 'fuelLogs', 'f1'), { status: 'approved' }));
    await assertFails(updateDoc(doc(admin(), 'fuelLogs', 'f1'), { status: 'approved', reviewedAt: Timestamp.now() }));
  });
  it('admin marks flags reviewed', async () => {
    await assertSucceeds(updateDoc(doc(admin(), 'fuelLogs', 'f1'), { flagsReviewed: true }));
  });
  it('admin cannot change typed fields or evidence', async () => {
    await assertFails(updateDoc(doc(admin(), 'fuelLogs', 'f1'), { liters: 1 }));
    await assertFails(updateDoc(doc(admin(), 'fuelLogs', 'f1'), { evidence: [] }));
  });
  it('driver cannot approve or add a review note', async () => {
    await assertFails(updateDoc(doc(driver(), 'fuelLogs', 'f1'), { status: 'approved', reviewedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(driver(), 'fuelLogs', 'f1'), { reviewNote: 'fine' }));
  });
});

// =====================================================================
describe('deletes are always denied', () => {
  beforeEach(async () => {
    await startTrip(driver());
    await createFill(driver());
    await editLog(driver(), 'fuelLogs', 'f1', { liters: 11 }, fillPrev);
    await setDoc(doc(admin(), 'places', 'p1'), { name: 'Home', lat: 1, lng: 2, radiusM: 150 });
    await setDoc(doc(admin(), 'vehicle', 'main'), { name: 'Alto', plate: 'X', fuelType: 'petrol' });
  });

  for (const [who, db] of [['driver', () => driver()], ['admin', () => admin()]]) {
    it(`${who} cannot delete anything`, async () => {
      await assertFails(deleteDoc(doc(db(), 'trips', 't1')));
      await assertFails(deleteDoc(doc(db(), 'trips', 't1', 'private', 'geo')));
      await assertFails(deleteDoc(doc(db(), 'fuelLogs', 'f1')));
      await assertFails(deleteDoc(doc(db(), 'fuelLogs', 'f1', 'private', 'geo')));
      await assertFails(deleteDoc(doc(db(), 'fuelLogs', 'f1', 'edits', 'e1')));
      await assertFails(deleteDoc(doc(db(), 'places', 'p1')));
      await assertFails(deleteDoc(doc(db(), 'vehicle', 'main')));
      await assertFails(deleteDoc(doc(db(), 'users', ALI)));
    });
  }
});
