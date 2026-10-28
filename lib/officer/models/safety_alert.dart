import 'package:cloud_firestore/cloud_firestore.dart';

class SafetyAlert {
  final String id;
  final String title;
  final String description;
  final String country;
  final String type;
  final String risk;
  final String sourceName;
  final String sourceUrl;
  final String status;
  final bool isEmergency;
  final double? latitude;
  final double? longitude;
  final double? radiusKm;
  final DateTime? createdAt;
  final DateTime? endDate;

  const SafetyAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.country,
    this.type = 'Travel Advisory',
    this.risk = 'Medium',
    this.sourceName = '',
    this.sourceUrl = '',
    this.status = 'Active',
    this.isEmergency = false,
    this.latitude,
    this.longitude,
    this.radiusKm,
    this.createdAt,
    this.endDate,
  });

  factory SafetyAlert.fromMap(String id, Map<String, dynamic> data) {
    DateTime? readDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    return SafetyAlert(
      id: id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      country: data['country'] as String? ?? '',
      type: data['type'] as String? ?? 'Travel Advisory',
      risk: data['risk'] as String? ?? 'Medium',
      sourceName: data['sourceName'] as String? ?? '',
      sourceUrl: data['sourceUrl'] as String? ?? '',
      status: data['status'] as String? ?? 'Active',
      isEmergency: data['isEmergency'] as bool? ?? false,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      radiusKm: (data['radiusKm'] as num?)?.toDouble(),
      createdAt: readDate(data['createdAt']),
      endDate: readDate(data['endDate']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'country': country,
      'type': type,
      'risk': risk,
      'sourceName': sourceName,
      'sourceUrl': sourceUrl,
      'status': status,
      'isEmergency': isEmergency,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (radiusKm != null) 'radiusKm': radiusKm,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
    };
  }
}
