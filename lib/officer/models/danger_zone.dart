import 'package:cloud_firestore/cloud_firestore.dart';

class DangerZone {
  final String id;
  final String name;
  final String zoneType;
  final double latitude;
  final double longitude;
  final double radius;
  final String description;
  final String country;
  final String risk;
  final String createdBy;
  final DateTime? createdAt;
  final bool isActive;

  const DangerZone({
    required this.id,
    required this.name,
    required this.zoneType,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.country,
    this.description = '',
    this.risk = 'High',
    this.createdBy = '',
    this.createdAt,
    this.isActive = true,
  });

  factory DangerZone.fromMap(String id, Map<String, dynamic> data) {
    final timestamp = data['createdAt'];

    return DangerZone(
      id: id,
      name: data['name'] as String? ?? '',
      zoneType: data['zoneType'] as String? ?? 'Danger',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
      radius: (data['radius'] as num?)?.toDouble() ?? 2,
      description: data['description'] as String? ?? '',
      country: data['country'] as String? ?? '',
      risk: data['risk'] as String? ?? 'High',
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'zoneType': zoneType,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'description': description,
      'country': country,
      'risk': risk,
      'createdBy': createdBy,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      'isActive': isActive,
    };
  }
}
