import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../src/AlarmModel.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class SecondScreen extends StatefulWidget {
  SecondScreen({Key? key, required this.title}) : super(key: key);

  static const String routeName = "/SecondScreen";

  final String title;

  @override
  _SecondScreenState createState() => new _SecondScreenState();
}

/// // 1. After the page has been created, register it with the app routes
/// routes: <String, WidgetBuilder>{
///   MyItemsPage.routeName: (BuildContext context) => new MyItemsPage(title: "MyItemsPage"),
/// },
///
/// // 2. Then this could be used to navigate to the page.
/// Navigator.pushNamed(context, MyItemsPage.routeName);
///

class _SecondScreenState extends State<SecondScreen> {
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as AlarmModel;
    FirebaseFirestore db = FirebaseFirestore.instance;

    var button = new IconButton(
        icon: new Icon(Icons.arrow_back), onPressed: _onButtonPressed);
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: StreamBuilder(
          stream: db
              .collection('users')
              .doc(_auth.currentUser?.uid)
              .collection("medicines")
              .where("alarm_id", isEqualTo: args.id)
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
            if (!streamSnapshot.hasData) {
              return CircularProgressIndicator();
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
                          constraints: BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                            maxWidth: 64,
                            maxHeight: 64,
                          ),
                          //child: Image.asset(profileImage, fit: BoxFit.cover),
                          child: new FutureBuilder<String>(
                            future: loadImage(documentSnapshot.id),
                            builder: (BuildContext context,
                                AsyncSnapshot<String> image) {
                              if (image.hasData) {
                                return new RotationTransition(
                                    turns: new AlwaysStoppedAnimation(documentSnapshot['rotation'] / 360),
                                    child: Image.network(image.data.toString()),
                                );// image is ready
                                //return Text('data');
                              } else {
                                return new Container(); // placeholder
                              }
                            },
                          )),
                      title: Text(documentSnapshot['name']),
                      subtitle: Text(documentSnapshot['description']),
                    ),
                  );
                },
              );
            } else {
              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text("No Medicines Found"),
                ),
              );
            }
          }),
      floatingActionButton: new FloatingActionButton(
        onPressed: _onFloatingActionButtonPressed,
        tooltip: 'Add',
        child: new Icon(Icons.add),
      ),
    );
  }

  void _onFloatingActionButtonPressed() {}

  void _onButtonPressed() {
    Navigator.pop(context);
  }

  Future<String> loadImage(String medId) async {
    //current user id
    final userID = FirebaseAuth.instance.currentUser!.uid;

    //collect the image name
    DocumentSnapshot variable = await FirebaseFirestore.instance
        .collection('users')
        .doc(userID)
        .collection('medicines')
        .doc(medId)
        .get();

    Reference ref = FirebaseStorage.instance.refFromURL(variable["imageDL"]);

    //get image url from firebase storage
    var url = await ref.getDownloadURL();
    //print('url: ' + url);
    return url;
  }
}
