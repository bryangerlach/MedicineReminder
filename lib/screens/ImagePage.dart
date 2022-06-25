import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
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
                          onPressed: () => _showCamera(context, args.id)),
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

  void _showCamera(BuildContext context, String id) async {

    final cameras = await availableCameras();
    final camera = cameras.first;

    final result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => TakePicturePage(camera: camera)));
    setState(() {
      //_path = result;
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

class TakePicturePage extends StatefulWidget {
  final CameraDescription camera;
  TakePicturePage({required this.camera});

  @override
  _TakePicturePageState createState() => _TakePicturePageState();
}

class _TakePicturePageState extends State<TakePicturePage> {
  late CameraController _cameraController;
  late Future<void> _initializeCameraControllerFuture;

  @override
  void initState() {
    super.initState();

    _cameraController =
        CameraController(widget.camera, ResolutionPreset.medium);

    _initializeCameraControllerFuture = _cameraController.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
      FutureBuilder(
        future: _initializeCameraControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_cameraController);
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    ]);
  }

  Future<void> _takePicture(BuildContext context) async {
    try {
      await _initializeCameraControllerFuture;

      //final path =
      //join((await getTemporaryDirectory()).path, '${DateTime.now()}.png');

      final path = await _cameraController.takePicture();

      Navigator.pop(context,path);

    } catch (e) {
      print(e);
    }
  }
}
