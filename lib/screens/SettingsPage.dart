import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
bool isShared = false;
String sharedUser = "";

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);
  static const String routeName = "/SettingsPage";

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _persistenceCheckbox = false;
  bool _sharedCalCheckbox = false;
  int _snoozeValue = 10;
  String _sharedCalUser = "";

  @override
  void initState() {
    super.initState();

    //_loadIsSharedValue();
    //_loadCalUserValue();
    _loadSwitchValue();
    _loadSnoozeValue();
  }

  _loadSwitchValue() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _persistenceCheckbox = (prefs.getBool('note_persistence')) ?? false;
      //_sharedCalCheckbox = (prefs.getBool('shared_cal')) ?? false;
    });
  }

  Future<String> _loadSnoozeValue() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _snoozeValue = (prefs.getInt('snooze_minutes')) ?? 10;
    return _snoozeValue.toString();
  }

  Future<String> _loadCalUserValue() async {
    final DocumentReference docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_auth.currentUser?.uid);
    await docRef.get().then(
            (DocumentSnapshot doc) {
                _sharedCalUser = doc['sharedUser'];
            });
    return _sharedCalUser;
  }

  Future<bool> _loadIsSharedValue() async {
    final DocumentReference docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_auth.currentUser?.uid);
    await docRef.get().then(
            (DocumentSnapshot doc) {
          _sharedCalCheckbox = doc['isShared'];
        });
    return _sharedCalCheckbox;
  }

  _saveSwitchValue() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setBool('note_persistence', _persistenceCheckbox);
    });
  }

  _saveSnoozeValue() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setInt('snooze_minutes', _snoozeValue);
    });
  }

  _saveCalUser() async {
    await FirebaseFirestore.instance.collection('users').doc(_auth.currentUser?.uid).update({'sharedUser': _sharedCalUser});
    setState(() {});
  }

  _saveSharedCal() async {
    await FirebaseFirestore.instance.collection('users').doc(_auth.currentUser?.uid).update({'isShared': _sharedCalCheckbox});
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Medicine Reminder'),
        ),
        // Use a StreamBuilder to display alarms from Firestore
        body: Center(
            child: Column(children: [
          CheckboxListTile(
            title: const Text('Persistent Notification'),
            value: _persistenceCheckbox,
            onChanged: (bool? value) {
              setState(() {
                _persistenceCheckbox = value!;
                _saveSwitchValue();
              });
            },
            secondary: const Icon(Icons.hourglass_empty),
          ),
          FutureBuilder<String>(
              future: _loadSnoozeValue(),
              builder: (
                BuildContext context,
                AsyncSnapshot<String> snapshot,
              ) {
                if (snapshot.hasData) {
                  return TextFormField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Snooze Minutes',
                        hintText: 'Snooze Minutes',
                      ),
                      initialValue: snapshot.data ?? "",
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      autofocus: false,
                      onChanged: (String text) {
                        _snoozeValue = int.parse('0$text');
                        _saveSnoozeValue();
                      });
                } else {
                  return const CircularProgressIndicator();
                }
              }),
              FutureBuilder<bool>(
                future: _loadIsSharedValue(), // Replace with your actual future
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final isSharedCalEnabled = snapshot.data!;
                    return CheckboxListTile(
                      title: const Text('Access Shared Calendar?'),
                      value: isSharedCalEnabled,
                      onChanged: (bool? value) {
                        setState(() {
                          _sharedCalCheckbox = value!;
                          _saveSharedCal(); // Update the setting based on the new value
                        });
                      },
                      secondary: const Icon(Icons.calendar_month),
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error fetching shared calendar setting: ${snapshot.error}');
                  } else {
                    return const CircularProgressIndicator(); // Show a loading indicator
                  }
                },
              ),
              FutureBuilder<String>(
                  future: _loadCalUserValue(),
                  builder: (
                      BuildContext context,
                      AsyncSnapshot<String> snapshot,
                      ) {
                    if (snapshot.hasData) {
                      return TextFormField(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Shared User',
                            hintText: 'Shared User',
                          ),
                          initialValue: snapshot.data ?? "",
                          keyboardType: TextInputType.text,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.singleLineFormatter
                          ],
                          autofocus: false,
                          onChanged: (String text) {
                            _sharedCalUser = text;
                            _saveCalUser();
                          });
                    } else {
                      return const CircularProgressIndicator();
                    }
                  }),
        ])));
  }
}
