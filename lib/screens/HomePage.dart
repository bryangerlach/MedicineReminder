import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medicinereminderflutter/src/AlarmModel.dart';
import 'package:medicinereminderflutter/screens/AuthGate.dart';
import 'package:medicinereminderflutter/screens/HistoryPage.dart';
import 'package:medicinereminderflutter/screens/MedicinesPage.dart';
import 'package:medicinereminderflutter/screens/DoctorsPage.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TimeOfDay selectedTime = TimeOfDay.now();
  final TextEditingController _timeController = TextEditingController();

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
      _timeController.text = documentSnapshot['timeVal'];
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
          "isOn": false
        });
      }

      if (action == 'update') {
        // update the current alarm time
        await _alarms.doc(documentSnapshot!.id).update({
          "timeVal": "${selectedTime.hour}:${selectedTime.minute}"
        });
      }
    }
  }

  Future<void> _deleteAlarm(DocumentSnapshot? documentSnapshot) async {
    await _alarms.doc(documentSnapshot?.id).delete();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You have successfully deleted an alarm')));
  }

  Future<void> _viewAlarm(String alarmId, bool isOn, String timeVal) async {
    Navigator.pushNamed(context, MedicinesPage.routeName,
        arguments: AlarmModel(alarmId, isOn, timeVal));
  }

  Future<void> _updateAlarmStatus(
      DocumentSnapshot? documentSnapshot, bool value) async {
    await _alarms.doc(documentSnapshot!.id).update({"isOn": value});
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
                // Update the state of the app.
                // ...
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
                      onPressed: () =>
                          _createOrUpdate(documentSnapshot),
                      child: Text(documentSnapshot['timeVal'])),
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
                              onPressed: () =>
                                  _deleteAlarm(documentSnapshot)),
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
