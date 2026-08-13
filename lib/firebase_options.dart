import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for fuchsia - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCgykZOz9XPRqUXcdN_I9B2L2SVOxKWeKk',
    appId: '1:558033653580:android:4de34291949d8e10eac9e9',
    messagingSenderId: '558033653580',
    projectId: 'ximmobilien24',
    storageBucket: 'ximmobilien24.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDVkpIg9fFRnPEtGnauOBjliAeRzMjIQgs',
    appId: '1:558033653580:ios:e586d7714aceda79eac9e9',
    messagingSenderId: '558033653580',
    projectId: 'ximmobilien24',
    storageBucket: 'ximmobilien24.firebasestorage.app',
    androidClientId: '558033653580-1fudl9bs6pfqvh7fd9frnf1at0njp6s2.apps.googleusercontent.com',
    iosClientId: '558033653580-dk9ucs89bc93c72v306uqvbi1pisaav4.apps.googleusercontent.com',
    iosBundleId: 'com.ebroker.wrteam',
  );
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDxbh8VwLdiKMCNuSRmlcdY3oqW1CrMl_4',
    appId: '1:558033653580:web:029c7caf102f696feac9e9',
    messagingSenderId: '558033653580',
    projectId: 'ximmobilien24',
    authDomain: 'ximmobilien24.firebaseapp.com',
    storageBucket: 'ximmobilien24.firebasestorage.app',
    measurementId: 'G-0WWEB1CPEE',
  );
}
