import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../src/MedicineModel.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../src/MedicinesCode.dart';

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
  String medId = "";
  bool firstRun = true;
  @override
  void initState() {
    super.initState();
    //imageRotation = 0;
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as MedicineModel;
    if (firstRun) {
      setState(() {
        imageRotation = args.rotation;
        medId = args.id;
      });
      firstRun = false;
    }
    return Scaffold(
        appBar: AppBar(
          title: const Text('Medicine Reminder'),
        ),
        // Use a StreamBuilder to display alarms from Firestore
        body: Column(children: [
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
                    onPressed: () => _showCamera(context, args.id)),
              ],
            ),
          ),
          FutureBuilder<String>(
            future: MedicinesCode.loadImage(_meds,medId),
            builder: (BuildContext context, AsyncSnapshot<String> image) {
              if (image.hasData && !kIsWeb) {
                return Center(
                    child: InteractiveViewer(
                        panEnabled: false, // Set it to false
                        boundaryMargin: EdgeInsets.all(100),
                        minScale: 1,
                        maxScale: 10,
                        child: RotationTransition(
                          turns: AlwaysStoppedAnimation(imageRotation / 360),
                          child: Image.file(File(image.data.toString())),
                        ))); // image is ready
              } else if(image.hasData && kIsWeb) {
                return Expanded(
                    child: InteractiveViewer(
                        panEnabled: false, // Set it to false
                        boundaryMargin: EdgeInsets.all(100),
                        minScale: 1,
                        maxScale: 10,
                        child: RotationTransition(
                          turns: AlwaysStoppedAnimation(imageRotation / 360),
                          child: Image.network(image.data.toString()),
                        ))); // image is ready
              } else {
                return Container(); // placeholder while awaiting image
              }
            },
          ),
        ]));
  }

  void _rotateImage(String id, int rotation) {
    int newRotation;
    if (rotation == 0) {
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

  void _showCamera(BuildContext context, String id) async {
    if(kIsWeb) {
      final ImagePicker _picker = ImagePicker();
      XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      String? path = photo?.path;
      Uint8List imageData = await XFile(path!).readAsBytes();
      _uploadImageWeb(imageData,id, photo?.name);
    } else {
      final ImagePicker _picker = ImagePicker();
      XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      print(photo?.path);
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String appDocPath = appDocDir.path;
      String imagePath = '$appDocPath/${photo?.name}';
      photo?.saveTo(imagePath);
      print(imagePath);
      _uploadImage(photo!, id);
    }
  }

  Future<void> _uploadImageWeb(Uint8List imageData, String id, String? name) async {
    final storage = FirebaseStorage.instanceFor(
        bucket: "gs://medicine-reminders.appspot.com");
    final storageRef = FirebaseStorage.instance.ref();
    final imageRef = storageRef.child("images/${name!}");
    //UploadTask uploadTask = storageRef.putData(imageData);
    try {
      await imageRef.putData(imageData);
      String imageDL = await imageRef.getDownloadURL();
      _meds.doc(id).update({"image": name, "imageDL": imageDL});
      setState(() {});
    } on FirebaseException catch (e) {
      print("error uploading file");
    }
  }

  Future<void> _uploadImage(XFile image, String id) async {
    final storage = FirebaseStorage.instanceFor(
        bucket: "gs://medicine-reminders.appspot.com");
    final storageRef = FirebaseStorage.instance.ref();
    final imageRef = storageRef.child("images/" + image.name);
    File file = File(image.path);
    try {
      await imageRef.putFile(file);
      String imageDL = await imageRef.getDownloadURL();
      _meds.doc(id).update({"image": image.name, "imageDL": imageDL});
      setState(() {});
    } on FirebaseException catch (e) {
      print("error uploading file");
    }
  }
}
