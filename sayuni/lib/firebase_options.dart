import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for Zion Jerusalem Mobile App
/// matching the active cloud project: zion-fellowship-church
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        // iOS is not configured yet: there is no GoogleService-Info.plist
        // and no iOS appId. Previously this silently reused the Android
        // appId, which makes iOS builds fail at Firebase init. Fail with
        // a clear message instead of a cryptic crash.
        throw UnsupportedError(
          'iOS Firebase is not configured. Add GoogleService-Info.plist '
          'and a real iOS FirebaseOptions before building for iOS. '
          'Android and Web are supported for the demo.',
        );
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB4I1tmrPahB1OREVNyRYOtAwI8DMFBVJc',
    appId: '1:295105770990:web:41993a079016819590caff',
    messagingSenderId: '295105770990',
    projectId: 'zion-mbagala-church',
    authDomain: 'zion-mbagala-church.firebaseapp.com',
    storageBucket: 'zion-mbagala-church.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAl_mOkECC4N4rEqS_dXaSUzoML6NFmlwM',
    appId: '1:295105770990:android:bd6b4fbcf701932490caff',
    messagingSenderId: '295105770990',
    projectId: 'zion-mbagala-church',
    storageBucket: 'zion-mbagala-church.firebasestorage.app',
  );

  // TODO(iOS): replace with real iOS options once GoogleService-Info.plist
  // is added. Do NOT reuse the Android appId here.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAl_mOkECC4N4rEqS_dXaSUzoML6NFmlwM',
    appId: '1:295105770990:ios:REPLACE_WITH_IOS_APP_ID',
    messagingSenderId: '295105770990',
    projectId: 'zion-mbagala-church',
    storageBucket: 'zion-mbagala-church.firebasestorage.app',
    iosBundleId: 'com.zion.app',
  );
}
