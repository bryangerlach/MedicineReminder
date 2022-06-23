import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../src/MedicineModel.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final CollectionReference _meds = FirebaseFirestore.instance
    .collection('users')
    .doc(_auth.currentUser?.uid)
    .collection("medicines");

class ImagePage extends StatefulWidget {
  const ImagePage({Key? key}) : super(key: key);
  static const String routeName = "/ImagePage";

  @override
  _ImagePageState createState() => _ImagePageState();
}

class _ImagePageState extends State<ImagePage> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as MedicineModel;
    return Scaffold(
        appBar: AppBar(
          title: const Text('Medicine Reminder'),
        ),
        // Use a StreamBuilder to display alarms from Firestore
        body: ListTile(
          leading: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 44,
                maxWidth: 64,
                maxHeight: 64,
              ),
              child: FutureBuilder<String>(
                future: loadImage(args.id),
                builder: (BuildContext context,
                    AsyncSnapshot<String> image) {
                  if (image.hasData) {
                    return RotationTransition(
                      turns: AlwaysStoppedAnimation(
                          args.rotation / 360),
                      child:
                      Image.network(image.data.toString()),
                    ); // image is ready
                  } else {
                    return Container(); // placeholder while awaiting image
                  }
                },
              )),
          //todo: add the taken checkbox
          title: Text("image"),
        ),
    );
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
