import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationsCode {
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
  }

  static Future<void> snoozed() async {
    print("snoozed");
    //todo: this should snooze the notification for x minutes
  }

  static Future<void> tapped() async {
    print("tapped");
  }
}