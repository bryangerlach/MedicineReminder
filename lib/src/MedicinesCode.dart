import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MedicinesCode {
  static Future<void> showMeds() async {

  }

  static Future<void> createEditMed(BuildContext context, TextEditingController _nameController,
      TextEditingController _descController, String action, CollectionReference _meds,
      String alarmId, DocumentSnapshot? documentSnapshot) async {
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
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  child: Text(action == 'create' ? 'Create' : 'Update'),
                  onPressed: () async {
                    final String name = _nameController.text;
                    final String desc = _descController.text;
                    if (action == 'create') {
                      // add a new medicine in the firestore database

                      await _meds.add({
                        "name": name,
                        "description": desc,
                        "alarm_id": alarmId
                      });
                    }

                    if (action == 'update') {
                      // update the current alarm time
                      await _meds
                          .doc(documentSnapshot!.id)
                          .update({"name": name, "description": desc});
                    }

                    _nameController.text = '';
                    _descController.text = '';

                    Navigator.of(context).pop();
                  },
                )
              ],
            ),
          );
        });
  }
}