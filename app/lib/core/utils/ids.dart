import 'dart:math';

final _random = Random.secure();
const _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

/// 20-character random ID, same shape as Firestore auto-IDs. Generated on the
/// phone so logs have their final IDs before they are ever uploaded.
String newId() => List.generate(20, (_) => _chars[_random.nextInt(_chars.length)]).join();
