import 'package:awesome_notifications/awesome_notifications.dart';

class NotificationsCode {
  //todo: make these function work
  static Future<void> taken(ReceivedNotification receivedNotification) async {
    print("taken");
    print(receivedNotification.payload?["alarmId"]);
    //todo: match the alarmId received with ones from the medicine firestore
  }

  static Future<void> snoozed() async {
    print("snoozed");
  }

  static Future<void> tapped() async {
    print("tapped");
  }
}