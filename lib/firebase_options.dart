import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Chưa cấu hình Firebase Web.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'Firebase chưa cấu hình cho ${defaultTargetPlatform.name}.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDzaQZlvMUsKRM4T9It9Jrw9gMBKkNedWk',
    appId: '1:618709802263:android:e3a0dbf9e5d43aed892b52',
    messagingSenderId: '618709802263',
    projectId: 'phoneshop-3f7c4',
    storageBucket: 'phoneshop-3f7c4.firebasestorage.app',
  );
}
