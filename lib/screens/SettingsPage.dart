import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);
  static const String routeName = "/SettingsPage";

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _persistenceCheckbox = false;

  @override
  void initState() {
    super.initState();

    _loadSwitchValue();
  }

  _loadSwitchValue() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _persistenceCheckbox = (prefs.getBool('note_persistence')) ?? false;
    });
  }

  _saveSwitchValue() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setBool('note_persistence', _persistenceCheckbox);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Medicine Reminder'),
        ),
        // Use a StreamBuilder to display alarms from Firestore
        body: CheckboxListTile(
          title: const Text('Persistent Notification'),
          value: _persistenceCheckbox,
          onChanged: (bool? value) {
            setState(() {
              _persistenceCheckbox = value!;
              _saveSwitchValue();
            });
          },
          secondary: const Icon(Icons.hourglass_empty),
        ));
  }
}
