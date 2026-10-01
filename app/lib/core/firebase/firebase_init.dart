import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

/// Connects to Firebase (currently the tanktrail-dev project, see
/// firebase_options.dart) and turns on Firestore's offline cache.
Future<void> initFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Offline-first: reads come from the on-device cache and writes queue until
  // there is internet. Unlimited cache because data is never deleted and the
  // volume is small (~30 logs a day).
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
}
