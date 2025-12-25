import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyDx3eILJy34SCcc8u35CgpWmpPYHgCnlwE',
      appId: "1:165949212273:android:9b3d53c16eeba1b8bbbdd0",
      messagingSenderId: "165949212273",
      projectId: "smart-line-following-car",
      authDomain: "smart-line-following-car.firebaseapp.com",
      storageBucket: "smart-line-following-car.appspot.com",
    ),
  );

  runApp(MyApp());
}