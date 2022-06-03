import 'package:cloud_firestore/cloud_firestore.dart';

class MedicineModel {
  String alarm_id;
  String description;
  String image;
  String imageDL;
  int rotation;
  String name;
  String taken_date;
  String thumbDL;

  MedicineModel(
      {required this.alarm_id,
      required this.description,
      required this.image,
      required this.imageDL,
      required this.rotation,
      required this.name,
      required this.taken_date,
      required this.thumbDL});

  MedicineModel.fromJson(Map<String, Object?> json)
      : this(
          alarm_id: json['alarm_id']! as String,
          description: json['description']! as String,
          image: json['image']! as String,
          imageDL: json['imageDL']! as String,
          rotation: json['rotation']! as int,
          name: json['name']! as String,
          taken_date: json['taken_date']! as String,
          thumbDL: json['thumbDL']! as String,
        );

  Map<String, Object?> toJson() {
    return {
      'alarm_id': alarm_id,
      'description': description,
      'image': image,
      'imageDL': imageDL,
      'rotation': rotation,
      'name': name,
      'taken_date': taken_date,
      'thumbDL': thumbDL,
    };
  }

  factory MedicineModel.fromDocumentSnapshot(
      {required DocumentSnapshot<Map<String, dynamic>> doc}) {
    return MedicineModel(
      alarm_id: doc.data()!["alarm_id"],
      description: doc.data()!["description"],
      image: doc.data()!["image"],
      imageDL: doc.data()!["imageDL"],
      rotation: doc.data()!["rotation"],
      name: doc.data()!["name"],
      taken_date: doc.data()!["taken_date"],
      thumbDL: doc.data()!["thumbDL"],
    );
  }
}
