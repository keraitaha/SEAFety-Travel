import 'package:cloud_firestore/cloud_firestore.dart';

class DestinationModel {
  final String destinationid;
  final String name;
  final String country;
  final String region;
  final String description;
  final List<String> categories;
  final String imageurl;
  final bool published;
  final Timestamp? updatetime;

  DestinationModel({
    required this.destinationid,
    required this.name,
    required this.country,
    required this.region,
    required this.description,
    required this.categories,
    required this.imageurl,
    required this.published,
    this.updatetime,
  });

  factory DestinationModel.fromMap(String id, Map<String, dynamic> data) {
    return DestinationModel(
      destinationid: id,
      name: data['name'] ?? '',
      country: data['country'] ?? '',
      region: data['region'] ?? '',
      description: data['description'] ?? '',
      categories: List<String>.from(data['categories'] ?? []),
      imageurl: data['imageurl'] ?? '',
      published: data['published'] ?? false,
      updatetime: data['updatetime'],
    );
  }
}
