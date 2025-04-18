import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../src/EventModel.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class EditEvent extends StatefulWidget {
  final DateTime firstDate;
  final DateTime lastDate;
  final EventModel event;
  const EditEvent(
      {Key? key,
        required this.firstDate,
        required this.lastDate,
        required this.event})
      : super(key: key);

  @override
  State<EditEvent> createState() => _EditEventState();
}

class _EditEventState extends State<EditEvent> {
  late DateTime _selectedDate;
  late bool _isGood;
  late TextEditingController _titleController;
  late TextEditingController _descController;
  @override
  void initState() {
    super.initState();
    _selectedDate = widget.event.date;
    _titleController = TextEditingController(text: widget.event.title);
    _descController = TextEditingController(text: widget.event.description);
    _isGood = widget.event.isGood;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Event")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SizedBox(
            height: 200,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: _selectedDate,
              onDateTimeChanged: (DateTime newDateTime) {
                _selectedDate = newDateTime;
              },
            ),
          ),
          TextField(
            controller: _titleController,
            maxLines: 1,
            decoration: const InputDecoration(labelText: 'title'),
          ),
          TextField(
            controller: _descController,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'description'),
          ),
          CheckboxListTile(
            title: const Text("Good"),
            value: _isGood,
            onChanged: (value) {
              setState(() {
                _isGood = value ?? false; // Handle null safety
              });
            },
          ),
          ElevatedButton(
            onPressed: () {
              _addEvent();
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _addEvent() async {
    final title = _titleController.text;
    final description = _descController.text;
    if (title.isEmpty) {
      print('title cannot be empty');
      return;
    }
    await FirebaseFirestore.instance.collection('users').doc(widget.event.userId).collection('events').doc(widget.event.id).update({
      "title": title,
      "description": description,
      "date": Timestamp.fromDate(_selectedDate),
      "good": _isGood,
    });
    if (mounted) {
      Navigator.pop<bool>(context, true);
    }
  }
}