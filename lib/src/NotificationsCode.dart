import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:medicinereminderflutter/src/AlarmsCode.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:move_to_background/move_to_background.dart';

class NotificationsCode {

  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    try{
      await Firebase.initializeApp(
          options: const FirebaseOptions(
              apiKey: "AIzaSyCkVX5xS4niK2gFJRgAE9oBuOJBNR2ZdeI",
              authDomain: "medicine-reminders.firebaseapp.com",
              projectId: "medicine-reminders",
              storageBucket: "medicine-reminders.appspot.com",
              messagingSenderId: "887354715842",
              appId: "1:887354715842:web:84279277e19bd45b19955b"));
    }  on FirebaseException catch (e) {
      print(e);
    }

    print(receivedAction.buttonKeyPressed);
    if(receivedAction.buttonKeyPressed == "TAKEN") {
      taken(receivedAction);
    } else if(receivedAction.buttonKeyPressed == "SNOOZE") {
      snoozed(receivedAction);
    }
  }

  static Future<void> initializeNotificationsEventListeners() async {
    AwesomeNotifications().setListeners(
          onActionReceivedMethod: onActionReceivedMethod,
          /*onNotificationCreatedMethod:
          NotificationsController.onNotificationCreatedMethod,
          onNotificationDisplayedMethod:
          NotificationsController.onNotificationDisplayedMethod,
          onDismissActionReceivedMethod:
          NotificationsController.onDismissActionReceivedMethod);*/
    );
  }

  static Future<void> taken(ReceivedNotification receivedNotification) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final CollectionReference meds = FirebaseFirestore.instance
        .collection('users')
        .doc(auth.currentUser?.uid)
        .collection("medicines");
    final CollectionReference history = FirebaseFirestore.instance
        .collection('users')
        .doc(auth.currentUser?.uid)
        .collection("history");
    DateTime now = DateTime.now();
    //String formattedDate = DateFormat.yMd().format(now);
    String formattedDate = "${now.year.toString()}/${now.month.toString().padLeft(2,'0')}/${now.day.toString().padLeft(2,'0')}";
    String formattedTime = DateFormat.Hm().format(now);
    meds.where("alarm_id", isEqualTo: receivedNotification.payload?["alarmId"])
      .get().then((res) {
      for (DocumentSnapshot documentSnapshot in res.docs) {
          meds.doc(documentSnapshot.id).update({"taken_date": formattedDate});
          history.add({"alarm_id": documentSnapshot["alarm_id"],
            "date": formattedDate, "med_id": documentSnapshot.id,
            "med_name": documentSnapshot["name"],
            "time": formattedTime,
          });
        }
    });
    if(!kIsWeb){MoveToBackground.moveTaskToBack();}
  }

  static Future<void> snoozed(ReceivedNotification receivedNotification) async {
    print("snoozed");
    final prefs = await SharedPreferences.getInstance();
    final int? snoozeMinutes = prefs.getInt('snooze_minutes');
    int sm = 10;
    if(snoozeMinutes != null) {
      sm = snoozeMinutes;
    }
    bool repeating = false;
    int hour = DateTime.now().hour;
    int minutes = DateTime.now().minute + sm;
    int notId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    String? alarmId = receivedNotification.payload?["alarmId"];
    AlarmsCode.setAlarmWithHM(hour,minutes,notId,alarmId!,repeating);
  }
}