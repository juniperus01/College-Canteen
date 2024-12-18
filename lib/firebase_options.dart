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
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyDmoPa8E2wyjvy0c3xgbNEHQifkQYeMs70',
    appId: '1:739108990298:android:ca59556fa7ab4e1a71d763',
    messagingSenderId: '739108990298',
    projectId: 'somato-81238',
    authDomain: 'somato-81238.firebaseapp.com',
    storageBucket: 'somato-81238.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDmoPa8E2wyjvy0c3xgbNEHQifkQYeMs70',
    appId: '1:739108990298:android:ca59556fa7ab4e1a71d763',
    messagingSenderId: '739108990298',
    projectId: 'somato-81238',
    storageBucket: 'somato-81238.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCYHrsbm_aWHtoKXXRZiQP_ZZNdkEGktdg',
    appId: '1:506953076147:ios:44c3623a2ec4c44dde8fc6',
    messagingSenderId: '506953076147',
    projectId: 'somato3',
    storageBucket: 'somato3.appspot.com',
    iosBundleId: 'com.example.flutterApplication1',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCYHrsbm_aWHtoKXXRZiQP_ZZNdkEGktdg',
    appId: '1:506953076147:ios:44c3623a2ec4c44dde8fc6',
    messagingSenderId: '506953076147',
    projectId: 'somato3',
    storageBucket: 'somato3.appspot.com',
    iosBundleId: 'com.example.flutterApplication1',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDmoPa8E2wyjvy0c3xgbNEHQifkQYeMs70',
    appId: '1:739108990298:android:ca59556fa7ab4e1a71d763',
    messagingSenderId: '739108990298',
    projectId: 'somato-81238',
    authDomain: 'somato-81238.firebaseapp.com',
    storageBucket: 'somato-81238.appspot.com',
  );

}