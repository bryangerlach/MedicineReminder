import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medicinereminderflutter/src/AlarmModel.dart';
import 'package:medicinereminderflutter/screens/AuthGate.dart';
import 'package:medicinereminderflutter/screens/HistoryPage.dart';
import 'package:medicinereminderflutter/screens/MedicinesPage.dart';
import 'package:medicinereminderflutter/screens/DoctorsPage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

final FirebaseAuth _auth = FirebaseAuth.instance;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TimeOfDay selectedTime = TimeOfDay.now();

  final CollectionReference _alarms = FirebaseFirestore.instance
      .collection('users')
      .doc(_auth.currentUser?.uid)
      .collection("alarms");

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, AuthGate.routeName);
  }

  Future<void> _createOrUpdate([DocumentSnapshot? documentSnapshot]) async {
    String action = 'create';
    if (documentSnapshot != null) {
      action = 'update';
    }

    final TimeOfDay? timeOfDay = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      initialEntryMode: TimePickerEntryMode.dial,
    );
    if (timeOfDay != null && timeOfDay != selectedTime) {
      setState(() {
        selectedTime = timeOfDay;
      });
      if (action == 'create') {
        // add a new alarm in the firestore database, default to turned off?
        await _alarms.add({
          "timeVal": "${selectedTime.hour}:${selectedTime.minute}",
          "isOn": false,
          "notifyId": DateTime.now().millisecondsSinceEpoch.remainder(100000)
        });
      }

      if (action == 'update') {
        // update the current alarm time
        await _alarms
            .doc(documentSnapshot!.id)
            .update({"timeVal": "${selectedTime.hour}:${selectedTime.minute}"});
        if(documentSnapshot['isOn']) {
          _setAlarmWithHM(selectedTime.hour, selectedTime.minute,
              documentSnapshot['notifyId']);
        }
      }
    }
  }

  Future<void> _deleteAlarm(DocumentSnapshot? documentSnapshot) async {
    await _alarms.doc(documentSnapshot?.id).delete();
    _cancelAlarm(documentSnapshot);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You have successfully deleted an alarm')));
  }

  Future<void> _viewAlarm(String alarmId, bool isOn, String timeVal) async {
    Navigator.pushNamed(context, MedicinesPage.routeName,
        arguments: AlarmModel(alarmId, isOn, timeVal));
  }

  Future<void> _updateAlarmStatus(
      DocumentSnapshot? documentSnapshot, bool value) async {
    if (!kIsWeb) {
      if (value) {
        _setAlarm(documentSnapshot);
      } else {
        _cancelAlarm(documentSnapshot);
      }
    }
    await _alarms.doc(documentSnapshot!.id).update({"isOn": value});
  }

  Future<void> _cancelAlarm(DocumentSnapshot? documentSnapshot) async {
    await AwesomeNotifications().cancel(documentSnapshot?['notifyId']);
  }

  Future<void> _setAlarmWithHM(int hour, int minutes, int notId) async {
    AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: notId,
            channelKey: 'basic_channel',
            title: 'Simple Notification',
            body: 'Simple body'),
        //schedule: NotificationCalendar.fromDate(date: _convertTime(hour, minutes), preciseAlarm: false, repeats: true,));
        schedule: NotificationCalendar(
            hour: hour,
            minute: minutes,
            second: 0,
            repeats: true,
            timeZone:
            await AwesomeNotifications().getLocalTimeZoneIdentifier()));
  }

  Future<void> _setAlarm(DocumentSnapshot? documentSnapshot) async {
    String stringTime = documentSnapshot?['timeVal'];
    int idx = stringTime.indexOf(":");
    List parts = [
      stringTime.substring(0, idx).trim(),
      stringTime.substring(idx + 1).trim()
    ];
    int hour = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);

    _setAlarmWithHM(hour, minutes, documentSnapshot?['notifyId']);
  }

  String _getTimeAMPM(String stringTime) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('Medicine Reminder'),
            ),
            ListTile(
              title: const Text('Medicines'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, MedicinesPage.routeName,
                    arguments: AlarmModel("all", false, "all"));
              },
            ),
            ListTile(
              title: const Text('Doctors'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, DoctorsPage.routeName);
              },
            ),
            ListTile(
              title: const Text('History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, HistoryPage.routeName);
              },
            ),
            ListTile(
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Log Out'),
              onTap: () {
                Navigator.pop(context);
                _signOut();
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Medicine Reminder'),
      ),
      // Use a StreamBuilder to display alarms from Firestore
      body: StreamBuilder(
        stream: _alarms.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            return ListView.builder(
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot documentSnapshot =
                    streamSnapshot.data!.docs[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    leading: Switch(
                        value: documentSnapshot['isOn'],
                        onChanged: (value) {
                          setState(() {
                            _updateAlarmStatus(documentSnapshot, value);
                          });
                        }),
                    title: TextButton(
                        onPressed: () => _createOrUpdate(documentSnapshot),
                        child: Text(
                          _getTimeAMPM(documentSnapshot['timeVal']),
                          style: const TextStyle(fontSize: 35),
                        )),
                    trailing: SizedBox(
                      width: 100,
                      child: Row(
                        children: [
                          // view alarm medicines button
                          IconButton(
                              icon: const Icon(Icons.medication_liquid_rounded),
                              onPressed: () => _viewAlarm(
                                  documentSnapshot.id,
                                  documentSnapshot['isOn'],
                                  documentSnapshot['timeVal'])),
                          // delete alarm button
                          IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteAlarm(documentSnapshot)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }

          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
      // Add new alarm
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createOrUpdate(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
