import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlarmsCode {

  static Future<void> setAlarm(DocumentSnapshot? documentSnapshot) async {
    String stringTime = documentSnapshot?['timeVal'];
    int idx = stringTime.indexOf(":");
    List parts = [
      stringTime.substring(0, idx).trim(),
      stringTime.substring(idx + 1).trim()
    ];
    int hour = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);

    setAlarmWithHM(hour, minutes, documentSnapshot?['notifyId'], documentSnapshot!.id);
  }

  static Future<void> getScheduledAlarms(CollectionReference alarms) async {
    Future<List<NotificationModel>> fetch() =>
        AwesomeNotifications().listScheduledNotifications();
    var schedule = await fetch();
    List<int?> idList = [];
    for (var item in schedule) {
      //add all notification ids to a list
      idList.add(item.content!.id);
    }
    alarms.get().then(
          (res) {
            for (DocumentSnapshot documentSnapshot in res.docs) { //all alarms
              if (idList.contains(documentSnapshot['notifyId'])) {
                //the id is already scheduled, we only check for alarm off state
                if(!documentSnapshot['isOn']) {cancelAlarm(documentSnapshot);}
              } else {
                //the id is not schedule, we only check for alarm on state
                if(documentSnapshot['isOn']) {setAlarm(documentSnapshot);}
              }
            }
          }
    );
  }

  static Future<void> setAlarmWithHM(int hour, int minutes, int notId, String alarmId) async {

    final prefs = await SharedPreferences.getInstance();
    final bool? np = prefs.getBool('note_persistence');
    bool notePersistence = false;
    if(np == null) {
      notePersistence = false;
      await prefs.setBool('note_persistence', false);
    } else {
      notePersistence = np;
    }

    AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: notId,
            channelKey: 'basic_channel',
            title: await getMedNames(alarmId),
            body: await getMedNames(alarmId),
            locked: notePersistence,
            payload: {"alarmId": alarmId},),

        actionButtons: [
          NotificationActionButton(
            key: 'TAKEN',
            label: 'Taken',
            buttonType: ActionButtonType.KeepOnTop,
          ),
          NotificationActionButton(
            key: 'SNOOZE',
            label: 'Snooze',
            buttonType: ActionButtonType.KeepOnTop,
          )
        ],
        //schedule: NotificationCalendar.fromDate(date: _convertTime(hour, minutes), preciseAlarm: false, repeats: true,));
        schedule: NotificationCalendar(
            hour: hour,
            minute: minutes,
            second: 0,
            repeats: true,
            timeZone:
            await AwesomeNotifications().getLocalTimeZoneIdentifier()));
  }

  static Future<String> getMedNames(String alarmId) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final Query meds = FirebaseFirestore.instance
        .collection('users')
        .doc(auth.currentUser?.uid)
        .collection("medicines");
    Future<List<String>> getData() async {
      List<String> medNames = [];
      var myMeds = await meds.where("alarm_id", isEqualTo: alarmId).get().then((res) {
        for (DocumentSnapshot documentSnapshot in res.docs) { //all alarms
          medNames.add("${documentSnapshot['name']}: ${documentSnapshot['description']}");
        }
        return medNames;
      });
      return myMeds;
    }
    var medicineName = await getData();
    String returnString = "";
    for (String item in medicineName) {
      returnString = "$returnString\n$item";
    }

    return returnString;
  }

  static String getTimeAMPM(String stringTime) {
    int idx = stringTime.indexOf(":");
    List parts = [
      stringTime.substring(0, idx).trim(),
      stringTime.substring(idx + 1).trim()
    ];
    int hour = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);
    String ampm;
    if (hour > 12) {
      hour = hour - 12;
      ampm = "PM";
    } else if (hour == 0) {
      hour = 12;
      ampm = "AM";
    } else {
      ampm = "AM";
    }

    String timeString =
        "$hour:${minutes.toString().padLeft(2, '0')} $ampm";
    return timeString;
  }

  static Future<void> cancelAlarm(DocumentSnapshot? documentSnapshot) async {
    await AwesomeNotifications().cancelSchedule(documentSnapshot?['notifyId']);
  }

  static Future<void> cancelAllAlarms() async {
    await AwesomeNotifications().cancelAllSchedules();
  }

  static Future<void> deleteAlarm(DocumentSnapshot? documentSnapshot,
      CollectionReference alarms, BuildContext context) async {
    await alarms.doc(documentSnapshot?.id).delete();
    cancelAlarm(documentSnapshot);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You have successfully deleted an alarm')));
  }

  static Future<void> updateAlarmStatus(
      DocumentSnapshot? documentSnapshot, bool value, CollectionReference alarms) async {
    if (!kIsWeb) {
      if (value) {
        setAlarm(documentSnapshot);
      } else {
        cancelAlarm(documentSnapshot);
      }
    }
    await alarms.doc(documentSnapshot!.id).update({"isOn": value});
  }
}