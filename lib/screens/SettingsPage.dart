import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);
  static const String routeName = "/SettingsPage";

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _persistenceCheckbox = false;
  int _snoozeValue = 10;

  @override
  void initState() {
    super.initState();

    _loadSwitchValue();
    _loadSnoozeValue();
  }

  _loadSwitchValue() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _persistenceCheckbox = (prefs.getBool('note_persistence')) ?? false;
    });
  }

  Future<String> _loadSnoozeValue() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _snoozeValue = (prefs.getInt('snooze_minutes')) ?? 10;
    return _snoozeValue.toString();
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
              })
        ])));
  }
}
