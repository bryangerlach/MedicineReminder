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
  int imageRotation = 0;
  bool firstRun = true;
  @override
  void initState() {
    super.initState();
    //imageRotation = 0;
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as MedicineModel;
    if(firstRun) {
      setState(() {
        imageRotation = args.rotation;
      });
      firstRun = false;
    }
    return Scaffold(
        appBar: AppBar(
          title: const Text('Medicine Reminder'),
        ),
        // Use a StreamBuilder to display alarms from Firestore
        body: Column(
          children: [
                SizedBox(
                  //width: 100,
                  child: Row(
                    children: [
                      TextButton.icon(
                          label: const Text("Rotate"),
                          icon: const Icon(Icons.rotate_left),
                          onPressed: () => _rotateImage(args.id, imageRotation)),
                      TextButton.icon(
                          label: const Text("Take Picture"),
                          icon: const Icon(Icons.camera_alt),
                          onPressed: () => _captureImage(args.id)),
                    ],
                  ),
                ),

            FutureBuilder<String>(
                future: loadImage(args.id),
                builder: (BuildContext context,
                    AsyncSnapshot<String> image) {
                  if (image.hasData) {
                    return RotationTransition(
                      turns: AlwaysStoppedAnimation(
                          imageRotation / 360),
                      child:
                      Image.network(image.data.toString()),
                    ); // image is ready
                  } else {
                    return Container(); // placeholder while awaiting image
                  }
                },
              ),
            ])
    );
  }

  void _rotateImage(String id, int rotation) {
    int newRotation;
    if(rotation == 0) {
      newRotation = 360;
    } else {
      newRotation = rotation - 90;
    }
    setState(() {
      imageRotation = newRotation;
    });
    final FirebaseAuth auth = FirebaseAuth.instance;
    final CollectionReference meds = FirebaseFirestore.instance
        .collection('users')
        .doc(auth.currentUser?.uid)
        .collection("medicines");
    meds.doc(id).update({"rotation": newRotation});
  }

  void _captureImage(String id) {
    print(id);
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
