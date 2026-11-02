import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _date(dynamic value) => value is Timestamp
    ? value.toDate()
    : value is DateTime
    ? value
    : null;

class Place {
  final String id;
  final String name;
  final String country;
  final String region;
  final String description;
  final List<String> categories;
  final String imageUrl;
  final String safetyLevel;
  final String openingHours;
  final String visaInfo;
  final String emergencyInfo;
  final String sourceUrl;
  final double? entranceFee;
  final String safetyInfo;

  const Place({
    required this.id,
    required this.name,
    required this.country,
    required this.region,
    required this.description,
    required this.categories,
    this.imageUrl = '',
    this.safetyLevel = 'unknown',
    this.openingHours = 'Check with the attraction',
    this.visaInfo = 'Check official immigration guidance',
    this.emergencyInfo = 'Contact local emergency services',
    this.sourceUrl = '',
    this.entranceFee,
    this.safetyInfo = '',
  });

  factory Place.fromMap(String id, Map<String, dynamic> data) => Place(
    id: id,
    name: '${data['name'] ?? ''}',
    country: '${data['country'] ?? ''}',
    region: '${data['region'] ?? ''}',
    description: '${data['description'] ?? ''}',
    categories: List<String>.from(data['categories'] ?? []),
    imageUrl: '${data['imageurl'] ?? ''}',
    safetyLevel: '${data['risk'] ?? data['safetylevel'] ?? 'unknown'}',
    safetyInfo: '${data['safetyInformation'] ?? ''}',
    openingHours: '${data['openinghours'] ?? 'Check with the attraction'}',
    visaInfo: '${data['visaInformation'] ?? data['visainfo'] ?? 'Check official immigration guidance'}',
    emergencyInfo: '${data['emergencyinfo'] ?? 'Contact local emergency services'}',
    sourceUrl: '${data['sourceUrl'] ?? data['sourceurl'] ?? ''}',
    entranceFee: (data['entrancefee'] as num?)?.toDouble(),
  );
}

class TravelPackage {
  final String id;
  final String agencyUserId;
  final String destinationId;
  final String title;
  final String description;
  final String imageUrl;
  final double price;
  final int durationDays;
  final List<String> inclusions;
  final String availability;

  const TravelPackage({
    required this.id,
    required this.agencyUserId,
    required this.destinationId,
    required this.title,
    required this.description,
    this.imageUrl = '',
    required this.price,
    required this.durationDays,
    required this.inclusions,
    this.availability = 'available',
  });

  factory TravelPackage.fromMap(String id, Map<String, dynamic> data) => TravelPackage(
    id: id,
    agencyUserId: '${data['agencyuserid'] ?? ''}',
    destinationId: '${data['destinationid'] ?? ''}',
    title: '${data['title'] ?? ''}',
    description: '${data['description'] ?? ''}',
    imageUrl: '${data['imageurl'] ?? ''}',
    price: (data['price'] as num?)?.toDouble() ?? 0,
    durationDays: (data['durationdays'] as num?)?.toInt() ?? 0,
    inclusions: List<String>.from(data['inclusions'] ?? []),
    availability: '${data['availability'] ?? 'available'}',
  );
}

class SafetyAlert {
  final String id;
  final String destinationId;
  final String country;
  final String region;
  final String title;
  final String description;
  final String riskType;
  final String riskLevel;
  final String sourceUrl;
  final DateTime? updatedAt;
  final String status;
  final DateTime? endDate;

  const SafetyAlert({
    required this.id,
    required this.destinationId,
    required this.country,
    required this.region,
    required this.title,
    required this.description,
    required this.riskType,
    required this.riskLevel,
    required this.sourceUrl,
    this.updatedAt,
    this.status = 'Active',
    this.endDate,
  });

  factory SafetyAlert.fromMap(String id, Map<String, dynamic> data, DateTime? updatedAt) => SafetyAlert(
    id: id,
    destinationId: '${data['destinationid'] ?? ''}',
    country: '${data['country'] ?? ''}',
    region: '${data['region'] ?? ''}',
    title: '${data['title'] ?? ''}',
    description: '${data['description'] ?? ''}',
    riskType: '${data['type'] ?? data['risktype'] ?? 'other'}',
    riskLevel: '${data['risk'] ?? data['risklevel'] ?? 'unknown'}',
    sourceUrl: '${data['sourceUrl'] ?? data['sourceurl'] ?? ''}',
    updatedAt: _date(data['createdAt']) ?? updatedAt,
    status: '${data['status'] ?? 'Active'}',
    endDate: _date(data['endDate']),
  );

  bool get isCurrent => status.toLowerCase() == 'active' && (endDate == null || endDate!.isAfter(DateTime.now()));

  bool appliesTo(Place place) =>
      isCurrent &&
      ((destinationId.isNotEmpty && destinationId == place.id) ||
          (destinationId.isEmpty &&
              country.toLowerCase() == place.country.toLowerCase() &&
              (region.isEmpty || region.toLowerCase() == place.region.toLowerCase())));
}

class TravelReview {
  final String targetId;
  final String targetType;
  final int rating;
  final String comment;
  const TravelReview({required this.targetId, required this.targetType, required this.rating, required this.comment});

  factory TravelReview.fromMap(Map<String, dynamic> data) => TravelReview(
    targetId: '${data['targetid'] ?? ''}',
    targetType: '${data['targettype'] ?? ''}',
    rating: (data['rating'] as num?)?.toInt() ?? 0,
    comment: '${data['comment'] ?? ''}',
  );
}

class Trip {
  final String id;
  final String title;
  final String destinationId;
  final String startDate;
  final String endDate;
  final double budget;
  final String status;
  final List<String> packageIds;

  const Trip({
    required this.id,
    required this.title,
    required this.destinationId,
    required this.startDate,
    required this.endDate,
    required this.budget,
    required this.status,
    required this.packageIds,
  });

  factory Trip.fromMap(String id, Map<String, dynamic> data) => Trip(
    id: id,
    title: '${data['tripname'] ?? ''}',
    destinationId: '${data['destinationid'] ?? ''}',
    startDate: '${data['startdate'] ?? ''}',
    endDate: '${data['enddate'] ?? ''}',
    budget: (data['budget'] as num?)?.toDouble() ?? 0,
    status: '${data['status'] ?? 'planned'}',
    packageIds: List<String>.from(data['packageids'] ?? []),
  );

  Map<String, dynamic> toMap(String ownerId) => {
    'userid': ownerId,
    'tripname': title.trim(),
    'destinationid': destinationId,
    'startdate': startDate,
    'enddate': endDate,
    'budget': budget,
    'currency': 'MYR',
    'status': status,
    'packageids': packageIds,
  };

  Trip withPackages(List<String> ids) => Trip(
    id: id,
    title: title,
    destinationId: destinationId,
    startDate: startDate,
    endDate: endDate,
    budget: budget,
    status: status,
    packageIds: ids,
  );
}

class Activity {
  final String id;
  final String name;
  final String date;
  final String time;
  final double cost;
  final String notes;
  final int order;

  const Activity({
    required this.id,
    required this.name,
    required this.date,
    this.time = '',
    required this.cost,
    this.notes = '',
    this.order = 0,
  });

  factory Activity.fromMap(String id, Map<String, dynamic> data) => Activity(
    id: id,
    name: '${data['activityname'] ?? ''}',
    date: '${data['date'] ?? ''}',
    time: '${data['time'] ?? ''}',
    cost: (data['estimatedcost'] as num?)?.toDouble() ?? 0,
    notes: '${data['notes'] ?? ''}',
    order: (data['sortorder'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'activityname': name.trim(),
    'date': date,
    'time': time,
    'estimatedcost': cost,
    'notes': notes,
    'sortorder': order,
  };
}

class ChatThread {
  final String id;
  final String staffId;
  final String type;
  final String? packageId;
  final String status;
  const ChatThread({required this.id, required this.staffId, required this.type, this.packageId, this.status = 'new'});
}

class ChatMessage {
  final String senderId;
  final String text;
  final DateTime createdAt;
  const ChatMessage({required this.senderId, required this.text, required this.createdAt});
}

class TripMath {
  static bool validDate(String value) {
    final date = DateTime.tryParse(value);
    return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) &&
        date != null &&
        date.toIso8601String().substring(0, 10) == value;
  }

  static String? validate(Trip trip) {
    if (trip.title.trim().isEmpty) return 'Enter a trip name.';
    if (trip.destinationId.isEmpty) return 'Select a destination.';
    final start = DateTime.tryParse(trip.startDate);
    final end = DateTime.tryParse(trip.endDate);
    if (!validDate(trip.startDate) || !validDate(trip.endDate) || start == null || end == null || end.isBefore(start)) {
      return 'Choose valid dates in the correct order.';
    }
    if (!trip.budget.isFinite || trip.budget < 0) {
      return 'Budget must be zero or greater.';
    }
    return null;
  }

  static double total(Trip trip, List<TravelPackage> packages, List<Activity> activities) {
    double result = 0;
    for (final id in trip.packageIds.toSet()) {
      for (final package in packages) {
        if (package.id == id &&
            package.destinationId == trip.destinationId &&
            package.price.isFinite &&
            package.price >= 0) {
          result += package.price;
        }
      }
    }
    for (final activity in activities) {
      result += activity.cost;
    }
    return result;
  }
}

String money(num value) => 'RM ${value.toStringAsFixed(2)}';
