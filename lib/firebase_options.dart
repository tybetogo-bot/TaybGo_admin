// Firebase configuration for the TaybGo Admin Firebase project.
//
// The web values come from the registered TaybGo Admin web app. The Android
// values come from the supplied google-services.json for com.taybgo.admin.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Firebase is not configured for $defaultTargetPlatform in TaybGo Admin.',
        );
      default:
        throw UnsupportedError(
          'Firebase is not configured for this platform in TaybGo Admin.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAx-JBKCauLhDIvMMLjztSVvq3k5PVc8CE',
    appId: '1:927010248626:web:e5c454c0568e9cff7636ab',
    messagingSenderId: '927010248626',
    projectId: 'taybgoadmin',
    authDomain: 'taybgoadmin.firebaseapp.com',
    storageBucket: 'taybgoadmin.firebasestorage.app',
    measurementId: 'G-3VMC8YVSYF',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyADDsAcF0OIcUCENClB1Snl7dDPtBablYI',
    appId: '1:927010248626:android:896e4faea9c737737636ab',
    messagingSenderId: '927010248626',
    projectId: 'taybgoadmin',
    storageBucket: 'taybgoadmin.firebasestorage.app',
  );
}
