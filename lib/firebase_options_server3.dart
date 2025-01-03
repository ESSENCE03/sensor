
// File: firebase_options_server3.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for Server 3
///
/// Example:
/// ```dart
/// import 'firebase_options_server3.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: FirebaseOptionsServer3.currentPlatform,
/// );
/// ```
class FirebaseOptionsServer3 {
static FirebaseOptions get currentPlatform {
if (kIsWeb) {
return web;
}
switch (defaultTargetPlatform) {
case TargetPlatform.android:
return android;
case TargetPlatform.iOS:
throw UnsupportedError(
'FirebaseOptionsServer3 has not been configured for iOS. '
'You can reconfigure this by running the FlutterFire CLI again.',
);
case TargetPlatform.macOS:
throw UnsupportedError(
'FirebaseOptionsServer3 has not been configured for macOS. '
'You can reconfigure this by running the FlutterFire CLI again.',
);
case TargetPlatform.windows:
return windows;
case TargetPlatform.linux:
throw UnsupportedError(
'FirebaseOptionsServer3 has not been configured for Linux. '
'You can reconfigure this by running the FlutterFire CLI again.',
);
default:
throw UnsupportedError(
'FirebaseOptionsServer3 are not supported for this platform.',
);
}
}

static const FirebaseOptions web = FirebaseOptions(
apiKey: 'AIzaSyXXXXX', // 서버 3 웹 키
appId: '1:574233998471:web:XXXXXX',
messagingSenderId: '574233998471',
projectId: 'thirdwinddata',
databaseURL: 'https://thirdwinddata-default-rtdb.asia-southeast1.firebasedatabase.app',
storageBucket: 'thirdwinddata.appspot.com',
);

static const FirebaseOptions android = FirebaseOptions(
apiKey: 'AIzaSyXXXXX', // 서버 3 안드로이드 키
appId: '1:574233998471:android:XXXXXX',
messagingSenderId: '574233998471',
projectId: 'thirdwinddata',
databaseURL: 'https://thirdwinddata-default-rtdb.asia-southeast1.firebasedatabase.app',
storageBucket: 'thirdwinddata.appspot.com',
);

static const FirebaseOptions windows = FirebaseOptions(
apiKey: 'AIzaSyXXXXX', // 서버 3 윈도우 키
appId: '1:574233998471:windows:XXXXXX',
messagingSenderId: '574233998471',
projectId: 'thirdwinddata',
databaseURL: 'https://thirdwinddata-default-rtdb.asia-southeast1.firebasedatabase.app',
storageBucket: 'thirdwinddata.appspot.com',
);
}
