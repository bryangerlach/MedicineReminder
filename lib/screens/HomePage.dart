import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../src/AlarmModel.dart';
import 'MedicinesPage.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // text fields' controllers
  final TextEditingController _timeController = TextEditingController();

  final CollectionReference _alarms = FirebaseFirestore.instance
      .collection('users')
      .doc(_auth.currentUser?.uid)
      .collection("alarms");

  Future<void> _createOrUpdate([DocumentSnapshot? documentSnapshot]) async {
    String action = 'create';
    if (documentSnapshot != null) {
      action = 'update';
      _timeController.text = documentSnapshot['timeVal'];
    }

    await showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext ctx) {
          return Padding(
            padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                // prevent the soft keyboard from covering text fields
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _timeController,
                  decoration: const InputDecoration(labelText: 'Time'),
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  child: Text(action == 'create' ? 'Create' : 'Update'),
                  onPressed: () async {
                    final String name = _timeController.text;
                    if (action == 'create') {
                      // add a new alarm in the firestore database, default to turned off?
                      await _alarms.add({"timeVal": name, "isOn": false});
                    }

                    if (action == 'update') {
                      // update the current alarm time
                      await _alarms
                          .doc(documentSnapshot!.id)
                          .update({"timeVal": name});
                    }

                    _timeController.text = '';

                    Navigator.of(context).pop();
                  },
                )
              ],
            ),
          );
        });
  }

  //
  Future<void> _viewAlarm(String alarmId, bool isOn, String timeVal) async {
    Navigator.pushNamed(context, MedicinesPage.routeName,
        arguments: AlarmModel(alarmId, isOn, timeVal));
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
                  // Update the state of the app.
                  // ...
                },
              ),
              ListTile(
                title: const Text('Doctors'),
                onTap: () {
                  // Update the state of the app.
                  // ...
                },
              ),
              ListTile(
                title: const Text('History'),
                onTap: () {
                  // Update the state of the app.
                  // ...
                },
              ),
              ListTile(
                title: const Text('Settings'),
                onTap: () {
                  // Update the state of the app.
                  // ...
                },
              ),
              ListTile(
                title: const Text('Log Out'),
                onTap: () {
                  // Update the state of the app.
                  // ...
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
                    title: Text(documentSnapshot['timeVal']),
                    subtitle: Text(documentSnapshot['isOn'].toString()),
                    trailing: SizedBox(
                      width: 100,
                      child: Row(
                        children: [
                          // edit alarm button
                          IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () =>
                                  _createOrUpdate(documentSnapshot)),
                          // view alarm medicines button
                          IconButton(
                              icon: const Icon(Icons.medication_liquid_rounded),
                              onPressed: () => _viewAlarm(
                                  documentSnapshot.id,
                                  documentSnapshot['isOn'],
                                  documentSnapshot['timeVal'])),
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
