import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase options for project `proenroll-4ff13`.
class DefaultFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDxcxKiT-6AjxDs-i3YBz--0qc8GI_xARA',
    appId: '1:1061331368492:android:a2e3e6e23b71191cafef89',
    messagingSenderId: '1061331368492',
    projectId: 'proenroll-4ff13',
    storageBucket: 'proenroll-4ff13.firebasestorage.app',
  );

  /// Register a Web app in Firebase Console → Project settings → Your apps,
  /// then replace `appId` with the web app id (`1:…:web:…`).
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDxcxKiT-6AjxDs-i3YBz--0qc8GI_xARA',
    appId: '1:1061331368492:web:proenroll',
    messagingSenderId: '1061331368492',
    projectId: 'proenroll-4ff13',
    authDomain: 'proenroll-4ff13.firebaseapp.com',
    storageBucket: 'proenroll-4ff13.firebasestorage.app',
  );

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }
}
