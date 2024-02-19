import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String title;
  final String? description;
  final DateTime date;
  final String id;
  final bool isGood;

  EventModel({
    required this.title,
    this.description,
    required this.date,
    required this.id,
    required this.isGood,
  });

  factory EventModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot,
      [SnapshotOptions? options]) {
    final data = snapshot.data()!;
    return EventModel(
      date: data['date'].toDate(),
      title: data['title'],
      description: data['description'],
      id: snapshot.id,
      isGood: data['good'] ?? false,
    );
  }

  Map<String, Object?> toFirestore() {
    return {
      "date": Timestamp.fromDate(date),
      "title": title,
      "description": description,
      "good": isGood
    };
  }
}