import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:medicinereminderflutter/src/AlarmModel.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final CollectionReference _meds = FirebaseFirestore.instance
    .collection('users')
    .doc(_auth.currentUser?.uid)
    .collection("medicines");

class MedicinesPage extends StatefulWidget {
  const MedicinesPage({Key? key, required this.title}) : super(key: key);

  static const String routeName = "/MedicinesPage";

  final String title;

  @override
  _MedicinesPageState createState() => _MedicinesPageState();
}

class _MedicinesPageState extends State<MedicinesPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as AlarmModel;
    var medStream;
    //FirebaseFirestore db = FirebaseFirestore.instance;
    if(args.id == "all") {
      medStream = _meds.snapshots();
    } else {
      medStream = _meds.where("alarm_id", isEqualTo: args.id).snapshots();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
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
                    child: ListTile(
                      leading: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                            maxWidth: 64,
                            maxHeight: 64,
                          ),
                          child: FutureBuilder<String>(
                            future: loadImage(documentSnapshot.id),
                            builder: (BuildContext context,
                                AsyncSnapshot<String> image) {
                              if (image.hasData) {
                                return RotationTransition(
                                  turns: AlwaysStoppedAnimation(
                                      documentSnapshot['rotation'] / 360),
                                  child: Image.network(image.data.toString()),
                                ); // image is ready
                              } else {
                                return Container(); // placeholder while awaiting image
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
                            IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    _createOrUpdate(documentSnapshot, args.id)),
                            // view alarm medicines button
                            IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () =>
                                    _deleteMedicine(documentSnapshot)),
                          ],
                        ),
                      ),
                    ),
                  );
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

  Future<String> loadImage(String medId) async {
    //collect the image name
    DocumentSnapshot variable = await _meds.doc(medId).get();

    Reference ref = FirebaseStorage.instance.refFromURL(variable["imageDL"]);

    //get image url from firebase storage
    var url = await ref.getDownloadURL();
    return url;
  }
}
