// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:medicinereminderflutter/screens/HomePage.dart';
import 'screens/AuthGate.dart';
import 'screens/MedicinesPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "AIzaSyCkVX5xS4niK2gFJRgAE9oBuOJBNR2ZdeI",
          authDomain: "medicine-reminders.firebaseapp.com",
          projectId: "medicine-reminders",
          storageBucket: "medicine-reminders.appspot.com",
          messagingSenderId: "887354715842",
          appId: "1:887354715842:web:84279277e19bd45b19955b"));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var routes = <String, WidgetBuilder>{
      '/': (context) => const AuthGate(),
      '/HomePage': (context) => const HomePage(),
      '/MedicinesPage': (context) => const MedicinesPage(title: "Medicines"),
      //MedicinesPage.routeName: (BuildContext context) => const MedicinesPage(title: "Medicines"),
    };
    return MaterialApp(
      // Remove the debug banner
      debugShowCheckedModeBanner: false,
      title: 'Medicine Reminder',
      initialRoute: '/',
      routes: routes,
    );
  }
}
