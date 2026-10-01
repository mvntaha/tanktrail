// Read-only: prints the latest trips and fuel logs in a Firebase project, to
// check what phones have synced. Never writes anything.
//   $env:GOOGLE_APPLICATION_CREDENTIALS="D:\secrets\tanktrail-dev-sa.json"
//   node scripts/inspect-logs.mjs tanktrail-dev-e514e
import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const projectId = process.argv[2];
if (!projectId) {
  console.error('Usage: node scripts/inspect-logs.mjs <projectId>');
  process.exit(1);
}
initializeApp({ credential: applicationDefault(), projectId });
const db = getFirestore();

for (const c of ['trips', 'fuelLogs']) {
  const s = await db.collection(c).orderBy('createdAt', 'desc').limit(10).get();
  console.log(`${c}: ${s.size} docs`);
  for (const d of s.docs) {
    const x = d.data();
    const ev = [...(x.startEvidence ?? x.evidence ?? []), ...(x.endEvidence ?? [])];
    const geo = (await d.ref.collection('private').doc('geo').get()).data() ?? {};
    const odo = `${x.startOdo ?? x.odometer}${x.endOdo ? '->' + x.endOdo : ''}`;
    console.log(
      `  ${d.id} ${x.driverName} status=${x.status} odo=${odo} files=${ev.length} [${ev.map((e) => e.type)}]` +
        ` geo=[${Object.keys(geo)}] coordsInPublicDoc=${JSON.stringify(x).includes('"lat"')}`,
    );
    for (const e of ev) console.log(`    ${e.type}: ${e.url}`);
  }
}
