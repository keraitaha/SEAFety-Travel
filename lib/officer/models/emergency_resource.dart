import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyResource {
  final String id;
  final String title;
  final String country;
  final String hostCountry;
  final String resourceType;
  final String phone;
  final String address;
  final String instructions;
  final String sourceUrl;
  final DateTime? lastUpdated;

  const EmergencyResource({
    required this.id,
    required this.title,
    required this.country,
    this.hostCountry = '',
    this.resourceType = 'Embassy',
    this.phone = '',
    this.address = '',
    this.instructions = '',
    this.sourceUrl = '',
    this.lastUpdated,
  });

  factory EmergencyResource.fromMap(String id, Map<String, dynamic> data) {
    final timestamp = data['lastUpdated'];

    return EmergencyResource(
      id: id,
      title: data['title'] as String? ?? '',
      country: data['country'] as String? ?? '',
      hostCountry: data['hostCountry'] as String? ?? '',
      resourceType: data['resourceType'] as String? ?? 'Embassy',
      phone: data['phone'] as String? ?? '',
      address: data['address'] as String? ?? '',
      instructions: data['instructions'] as String? ?? '',
      sourceUrl: data['sourceUrl'] as String? ?? '',
      lastUpdated: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'country': country,
      'hostCountry': hostCountry,
      'resourceType': resourceType,
      'phone': phone,
      'address': address,
      'instructions': instructions,
      'sourceUrl': sourceUrl,
      if (lastUpdated != null) 'lastUpdated': Timestamp.fromDate(lastUpdated!),
    };
  }
}
