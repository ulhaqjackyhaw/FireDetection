// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCKerVVynvh2puu7Cqe0wZQ5HNChogCH6c',
    appId: '1:696576915587:web:d7d02c2d5020821682c3b6',
    messagingSenderId: '696576915587',
    projectId: 'tubes-e7c2f',
    authDomain: 'tubes-e7c2f.firebaseapp.com',
    databaseURL: 'https://tubes-e7c2f-default-rtdb.firebaseio.com',
    storageBucket: 'tubes-e7c2f.firebasestorage.app',
    measurementId: 'G-ZK9PQFDJK7',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCpcrTwU-Q7pmTpgzFHlWLhI3liq96MPMI',
    appId: '1:696576915587:android:e35e7a0a844cd69a82c3b6',
    messagingSenderId: '696576915587',
    projectId: 'tubes-e7c2f',
    databaseURL: 'https://tubes-e7c2f-default-rtdb.firebaseio.com',
    storageBucket: 'tubes-e7c2f.firebasestorage.app',
  );
}
