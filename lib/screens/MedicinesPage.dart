import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:medicinereminderflutter/src/AlarmModel.dart';
import 'package:medicinereminderflutter/src/MedicineModel.dart';
import 'package:medicinereminderflutter/src/MedicinesCode.dart';
import 'package:medicinereminderflutter/screens/ImagePage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

//todo: capture image
//todo: taken today checkbox, makes entry to history

final FirebaseAuth _auth = FirebaseAuth.instance;
final CollectionReference _meds = FirebaseFirestore.instance
    .collection('users')
    .doc(_auth.currentUser?.uid)
    .collection("medicines");
final CollectionReference _medNames = FirebaseFirestore.instance
    .collection('users')
    .doc(_auth.currentUser?.uid)
    .collection("medicineNames");

class MedicinesPage extends StatefulWidget {
  const MedicinesPage({Key? key}) : super(key: key);

  static const String routeName = "/MedicinesPage";

  @override
  _MedicinesPageState createState() => _MedicinesPageState();
}

class _MedicinesPageState extends State<MedicinesPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as AlarmModel;
    Stream<QuerySnapshot<Object?>> medStream;
    //FirebaseFirestore db = FirebaseFirestore.instance;
    if (args.id == "all") {
      medStream = _meds.snapshots();
    } else {
      medStream = _meds.where("alarm_id", isEqualTo: args.id).snapshots();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Medicines"),
      ),
      body: StreamBuilder(
          stream: medStream,
          builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
            if (!streamSnapshot.hasData) {
              return const CircularProgressIndicator();
            }
            if (streamSnapshot.hasData) {
              return ListView.builder(
                itemCount: streamSnapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final DocumentSnapshot documentSnapshot =
                      streamSnapshot.data!.docs[index];
                  return Card(
                      margin: const EdgeInsets.all(10),
                      child: Column(children: [
                        ListTile(
                          leading: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 44,
                                maxWidth: 64,
                                maxHeight: 64,
                              ),
                              child: FutureBuilder<String>(
                                future: MedicinesCode.loadImage(_meds,documentSnapshot.id),
                                builder: (BuildContext context,
                                    AsyncSnapshot<String> image) {
                                  if (image.hasData && !kIsWeb) {
                                    return RotationTransition(
                                        turns: AlwaysStoppedAnimation(
                                            documentSnapshot['rotation'] / 360),
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.pushNamed(
                                                context, ImagePage.routeName,
                                                arguments: MedicineModel(
                                                    documentSnapshot.id,
                                                    documentSnapshot["alarm_id"],
                                                    documentSnapshot["description"],
                                                    documentSnapshot["image"],
                                                    documentSnapshot["imageDL"],
                                                    documentSnapshot["rotation"],
                                                    documentSnapshot["name"],
                                                    documentSnapshot["taken_date"],
                                                    documentSnapshot["thumbDL"]));
                                          },
                                          child: Image.file(
                                              File(image.data.toString())),
                                        )); // image is ready
                                  } else if (image.hasData && kIsWeb) {
                                    return RotationTransition(
                                        turns: AlwaysStoppedAnimation(
                                            documentSnapshot['rotation'] / 360),
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.pushNamed(
                                                context, ImagePage.routeName,
                                                arguments: MedicineModel(
                                                    documentSnapshot.id,
                                                    documentSnapshot["alarm_id"],
                                                    documentSnapshot["description"],
                                                    documentSnapshot["image"],
                                                    documentSnapshot["imageDL"],
                                                    documentSnapshot["rotation"],
                                                    documentSnapshot["name"],
                                                    documentSnapshot["taken_date"],
                                                    documentSnapshot["thumbDL"]));
                                          },
                                          child: Image.network(
                                              image.data.toString()),
                                        )); // image is ready
                                  } else {
                                    return TextButton.icon(
                                        label: const Text("Take Picture"),
                                        icon: const Icon(Icons.camera_alt),
                                        onPressed: () => Navigator.pushNamed(
                                        context, ImagePage.routeName,
                                  arguments: MedicineModel(
                                  documentSnapshot.id,
                                  documentSnapshot["alarm_id"],
                                  documentSnapshot["description"],
                                  documentSnapshot["image"],
                                  documentSnapshot["imageDL"],
                                  documentSnapshot["rotation"],
                                  documentSnapshot["name"],
                                  documentSnapshot["taken_date"],
                                  documentSnapshot["thumbDL"])));
                                  }
                                },
                              )),
                          title: Text(documentSnapshot['name']),
                          subtitle: Text(documentSnapshot['description']),
                          trailing: SizedBox(
                            width: 100,
                            child: Row(
                              children: [
                                // edit alarm button
                                TextButton.icon(
                                    label: const Text("Edit"),
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _createOrUpdate(
                                        documentSnapshot, args.id)),
                                // view alarm medicines button
                              ],
                            ),
                          ),
                        ),
                        ListTile(
                          leading: Checkbox(
                              value: _getTakenToday(
                                  documentSnapshot['taken_date']),
                              onChanged: (bool? value) {
                                bool today = value ?? false;
                                if (today) {
                                  _setTakenDate(true, documentSnapshot.id);
                                } else {
                                  _setTakenDate(false, documentSnapshot.id);
                                }
                              }),
                          title: const Text('Taken today?'),
                          trailing: TextButton.icon(
                              label: const Text("Delete"),
                              icon: const Icon(Icons.delete),
                              onPressed: () =>
                                  _deleteMedicine(documentSnapshot)),
                        ),
                      ]));
                },
              );
            } else {
              return const Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  title: Text("No Medicines Found"),
                ),
              );
            }
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onFloatingActionButtonPressed(args.id),
        tooltip: 'Add',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _onFloatingActionButtonPressed(String alarmId) async {
    _createOrUpdate(null, alarmId);
  }

  bool _getTakenToday(String takenDate) {
    DateTime now = DateTime.now();
    //String formattedDate = DateFormat.yMd().format(now);
    String formattedDate = "${now.year.toString()}/${now.month.toString().padLeft(2,'0')}/${now.day.toString()}";
    if (takenDate == formattedDate) {
      return true;
    } else {
      return false;
    }
  }

  void _setTakenDate(bool today, String medId) {
    DateTime now;
    if (today) {
      now = DateTime.now();
    } else {
      now = DateTime.now().subtract(const Duration(days: 1));
    }
    //String formattedDate = DateFormat.yMd().format(now);
    String formattedDate = "${now.year.toString()}/${now.month.toString().padLeft(2,'0')}/${now.day.toString()}";
    _meds.doc(medId).update({"taken_date": formattedDate});
  }

  Future<void> _deleteMedicine(DocumentSnapshot? documentSnapshot) async {
    await _meds.doc(documentSnapshot?.id).delete();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You have successfully deleted a medicine')));
  }

  Future<void> _createOrUpdate(
      DocumentSnapshot? documentSnapshot, String alarmId) async {
    String action = 'create';
    if (documentSnapshot != null) {
      action = 'update';
      _nameController.text = documentSnapshot['name'];
      _descController.text = documentSnapshot['description'];
    }
    //todo: this should first show a list of current meds (from _medNames) with an add button
    //todo: the add button does below, adds med to _medNames and _meds
    //todo: selecting a med only adds to _meds
    //MedicinesCode.showMeds();
    MedicinesCode.createEditMed(context, _nameController, _descController,
        action, _meds, alarmId, documentSnapshot);
  }
}
