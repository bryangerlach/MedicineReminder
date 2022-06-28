// main.dart
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:medicinereminderflutter/screens/DoctorsPage.dart';
import 'package:medicinereminderflutter/screens/HistoryPage.dart';
import 'package:medicinereminderflutter/screens/HomePage.dart';
import 'package:medicinereminderflutter/screens/AuthGate.dart';
import 'package:medicinereminderflutter/screens/ImagePage.dart';
import 'package:medicinereminderflutter/screens/MedicinesPage.dart';
import 'package:medicinereminderflutter/screens/SettingsPage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if(!kIsWeb) {notificationInit();}
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

void notificationInit() {
  AwesomeNotifications().initialize(
    // set the icon to null if you want to use the default app icon
      'resource://drawable/ic_small_pill',
      [
        NotificationChannel(
            channelGroupKey: 'basic_channel_group',
            channelKey: 'basic_channel',
            channelName: 'Basic notifications',
            channelDescription: 'Notification channel for basic tests',
            defaultColor: const Color(0xFF9D50DD),
            ledColor: Colors.white)
      ],
      // Channel groups are only visual and are not required
      channelGroups: [
        NotificationChannelGroup(
            channelGroupkey: 'basic_channel_group',
            channelGroupName: 'Basic group')
      ],
      debug: true);
  AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    if (!isAllowed) {
      // This is just a basic example. For real apps, you must show some
      // friendly dialog box before call the request method.
      // This is very important to not harm the user experience
      AwesomeNotifications().requestPermissionToSendNotifications();
    }
  });


}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var routes = <String, WidgetBuilder>{
      '/': (context) => const AuthGate(),
      '/HomePage': (context) => const HomePage(),
      '/MedicinesPage': (context) => const MedicinesPage(),
      '/HistoryPage': (context) => const HistoryPage(),
      '/DoctorsPage': (context) => const DoctorsPage(),
      '/SettingsPage': (context) => const SettingsPage(),
      '/ImagePage': (context) => const ImagePage(),
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
