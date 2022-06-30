import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class MedicinesCode {
  static Future<void> showMeds() async {

  }

  static Future<void> createEditMed(BuildContext context, TextEditingController nameController,
      TextEditingController descController, String action, CollectionReference meds,
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
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  child: Text(action == 'create' ? 'Create' : 'Update'),
                  onPressed: () async {
                    final String name = nameController.text;
                    final String desc = descController.text;
                    if (action == 'create') {
                      // add a new medicine in the firestore database

                      await meds.add({
                        "name": name,
                        "description": desc,
                        "alarm_id": alarmId,
                        "image": "",
                        "imageDL": "",
                        "rotation": 0,
                        "taken_date": "",
                        "thumbDL": "",
                      });
                    }

                    if (action == 'update') {
                      // update the current alarm time
                      await meds
                          .doc(documentSnapshot!.id)
                          .update({"name": name, "description": desc});
                    }

                    nameController.text = '';
                    descController.text = '';

                    Navigator.of(context).pop();
                  },
                )
              ],
            ),
          );
        });
  }

  static Future<String> loadImage(CollectionReference meds, String medId) async {
    DocumentSnapshot documentSnapshot = await meds.doc(medId).get();
    Reference ref = FirebaseStorage.instance.refFromURL(
        documentSnapshot["imageDL"]);
    String returnString;
    if(!kIsWeb) {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String appDocPath = appDocDir.path;

      File imageFile = File('$appDocPath/${documentSnapshot["image"]}');
      if (!imageFile.existsSync()) {
        final downloadImage = ref.writeToFile(imageFile);
        downloadImage.snapshotEvents.listen((taskSnapshot) {
          switch (taskSnapshot.state) {
            case TaskState.running:
            // TODO: Handle this case.
              break;
            case TaskState.paused:
            // TODO: Handle this case.
              break;
            case TaskState.success:
            //print(imageFile);
              loadImage(meds, medId);
              break;
            case TaskState.canceled:
            // TODO: Handle this case.
              break;
            case TaskState.error:
            //print("file does not exist on server");
              break;
          }
        });
      }
      returnString = imageFile.path;
    } else {
      returnString = await ref.getDownloadURL();
    }
      return returnString;
  }
}