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
    apiKey: 'AIzaSyD2aM8qC9FIaU-TzhzbyetVqGLrjGLfsJM',
    appId: '1:885243721274:web:e83c3bb3dfe224f191e703',
    messagingSenderId: '885243721274',
    projectId: 'photogallery-c6b81',
    authDomain: 'photogallery-c6b81.firebaseapp.com',
    storageBucket: 'photogallery-c6b81.appspot.com',
    measurementId: 'G-MDVV6SJNXP',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBuIhWclOFEynR-eSE2ixyPkP05d5C9ejE',
    appId: '1:885243721274:android:051e9aa3c5b49ad691e703',
    messagingSenderId: '885243721274',
    projectId: 'photogallery-c6b81',
    storageBucket: 'photogallery-c6b81.appspot.com',
  );
}