

import 'package:awesome_notifications/awesome_notifications.dart';

class Utility {

  static Future<void> taken() async {
    print("taken");
  }

  static Future<void> snoozed() async {
    print("snoozed");
  }

  static Future<void> tapped() async {
    print("tapped");
  }

  static Future<String> getScheduledAlarms() async {
    Future<List<NotificationModel>> fetch() =>
        AwesomeNotifications().listScheduledNotifications();
    var schedule = await fetch();
    schedule.forEach((item) {
      print('${item.content?.id.toString()} : ${item.schedule.toString()}');
    });
    return '$schedule';
  }

  static Future<void> checkSetAlarms() async {
    //todo: read the alarms db and check the scheduled alarms,
    //schedule any alarms that are on but not scheduled
    print(await getScheduledAlarms());
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

  static Future<void> setAlarmWithHM(int hour, int minutes, int notId) async {
    //todo: we need to get the medicine names and descriptions for the alarm
    AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: notId,
            channelKey: 'basic_channel',
            title: 'Simple Notification',
            body: 'Simple body'),
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
}