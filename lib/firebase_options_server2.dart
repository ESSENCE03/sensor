
// File: firebase_options_server2.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for Server 2
///
/// Example:
/// ```dart
/// import 'firebase_options_server2.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: FirebaseOptionsServer2.currentPlatform,
/// );
/// ```
class FirebaseOptionsServer2 {
static FirebaseOptions get currentPlatform {
if (kIsWeb) {
return web;
}
switch (defaultTargetPlatform) {
case TargetPlatform.android:
return android;
case TargetPlatform.iOS:
throw UnsupportedError(
'FirebaseOptionsServer2 has not been configured for iOS. '
'You can reconfigure this by running the FlutterFire CLI again.',
);
case TargetPlatform.macOS:
throw UnsupportedError(
'FirebaseOptionsServer2 has not been configured for macOS. '
'You can reconfigure this by running the FlutterFire CLI again.',
);
case TargetPlatform.windows:
return windows;
case TargetPlatform.linux:
throw UnsupportedError(
'FirebaseOptionsServer2 has not been configured for Linux. '
'You can reconfigure this by running the FlutterFire CLI again.',
);
default:
throw UnsupportedError(
'FirebaseOptionsServer2 are not supported for this platform.',
);
}
}

static const FirebaseOptions web = FirebaseOptions(
apiKey: 'AIzaSyXXXXX', // 서버 2 웹 키
appId: '1:557824746695:web:XXXXXX',
messagingSenderId: '557824746695',
projectId: 'secondwinddata',
databaseURL: 'https://secondwinddata-default-rtdb.asia-southeast1.firebasedatabase.app',
storageBucket: 'secondwinddata.appspot.com',
);

static const FirebaseOptions android = FirebaseOptions(
apiKey: 'AIzaSyXXXXX', // 서버 2 안드로이드 키
appId: '1:557824746695:android:XXXXXX',
messagingSenderId: '557824746695',
projectId: 'secondwinddata',
databaseURL: 'https://secondwinddata-default-rtdb.asia-southeast1.firebasedatabase.app',
storageBucket: 'secondwinddata.appspot.com',
);

static const FirebaseOptions windows = FirebaseOptions(
apiKey: 'AIzaSyXXXXX', // 서버 2 윈도우 키
appId: '1:557824746695:windows:XXXXXX',
messagingSenderId: '557824746695',
projectId: 'secondwinddata',
databaseURL: 'https://secondwinddata-default-rtdb.asia-southeast1.firebasedatabase.app',
storageBucket: 'secondwinddata.appspot.com',
);
}
