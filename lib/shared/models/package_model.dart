import 'package:cloud_firestore/cloud_firestore.dart';

class PackageModel {
  final String packageid;
  final String agencyuserid;
  final String destinationid;
  final String title;
  final String description;
  final String imageurl;
  final double price;
  final String currency;
  final int durationdays;
  final List<String> inclusions;
  final String availability; // available / limited / unavailable
  final bool published;
  final Timestamp? updatetime;

  PackageModel({
    required this.packageid,
    required this.agencyuserid,
    required this.destinationid,
    required this.title,
    required this.description,
    required this.imageurl,
    required this.price,
    required this.currency,
    required this.durationdays,
    required this.inclusions,
    required this.availability,
    required this.published,
    this.updatetime,
  });

  factory PackageModel.fromMap(String id, Map<String, dynamic> data) {
    return PackageModel(
      packageid: id,
      agencyuserid: data['agencyuserid'] ?? '',
      destinationid: data['destinationid'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageurl: data['imageurl'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'MYR',
      durationdays: data['durationdays'] ?? 0,
      inclusions: List<String>.from(data['inclusions'] ?? []),
      availability: data['availability'] ?? 'available',
      published: data['published'] ?? false,
      updatetime: data['updatetime'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'agencyuserid': agencyuserid,
      'destinationid': destinationid,
      'title': title,
      'description': description,
      'imageurl': imageurl,
      'price': price,
      'currency': currency,
      'durationdays': durationdays,
      'inclusions': inclusions,
      'availability': availability,
      'published': published,
      'updatetime': FieldValue.serverTimestamp(),
    };
  }
}
