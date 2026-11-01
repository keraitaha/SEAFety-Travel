import 'package:cloud_firestore/cloud_firestore.dart';

class OfficerFirebaseService {
  final FirebaseFirestore _db;

  OfficerFirebaseService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  static const List<String> southeastAsianCountries = [
    'Brunei',
    'Cambodia',
    'Indonesia',
    'Laos',
    'Malaysia',
    'Myanmar',
    'Philippines',
    'Singapore',
    'Thailand',
    'Timor-Leste',
    'Vietnam',
  ];

  static const int touristRole = 0;
  static const int travelAgencyRole = 1;
  static const int tourismOfficerRole = 2;

  static const List<int> validUserRoles = [
    touristRole,
    travelAgencyRole,
    tourismOfficerRole,
  ];

  CollectionReference<Map<String, dynamic>> get _destinations =>
      _db.collection('destinations');

  CollectionReference<Map<String, dynamic>> get _alerts =>
      _db.collection('safety_alerts');

  CollectionReference<Map<String, dynamic>> get _zones =>
      _db.collection('danger_zones');

  CollectionReference<Map<String, dynamic>> get _resources =>
      _db.collection('emergency_resources');

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');


  // DESTINATIONS

  Stream<QuerySnapshot<Map<String, dynamic>>> watchDestinations() {
    return _destinations.snapshots();
  }

  Future<void> addDestination(Map<String, dynamic> data) async {
    _validateCountry(data['country']);
    data['lastUpdated'] = FieldValue.serverTimestamp();
    await _destinations.add(data);
  }

  Future<void> updateDestination(
      String id, Map<String, dynamic> data) async {
    _validateCountry(data['country']);
    data['lastUpdated'] = FieldValue.serverTimestamp();
    await _destinations.doc(id).update(data);
  }

  Future<void> deleteDestination(String id) async {
    await _destinations.doc(id).delete();
  }


  // SAFETY ALERTS

  Stream<QuerySnapshot<Map<String, dynamic>>> watchAlerts() {
    return _alerts.snapshots();
  }

  Future<void> addAlert(Map<String, dynamic> data) async {
    _validateCountry(data['country']);
    data['createdAt'] = FieldValue.serverTimestamp();
    await _alerts.add(data);
  }

  Future<void> updateAlert(String id, Map<String, dynamic> data) async {
    _validateCountry(data['country']);
    await _alerts.doc(id).update(data);
  }

  Future<void> deleteAlert(String id) async {
    await _alerts.doc(id).delete();
  }

  // DANGER ZONES

  Stream<QuerySnapshot<Map<String, dynamic>>> watchZones() {
    return _zones.snapshots();
  }

  Future<void> addZone(Map<String, dynamic> data) async {
    _validateCountry(data['country']);
    data['createdAt'] = FieldValue.serverTimestamp();
    await _zones.add(data);
  }

  Future<void> deleteZone(String id) async {
    await _zones.doc(id).delete();
  }

  // EMERGENCY RESOURCES

  Stream<QuerySnapshot<Map<String, dynamic>>> watchResources() {
    return _resources.snapshots();
  }

  Future<void> addResource(Map<String, dynamic> data) async {
    _validateCountry(data['country']);
    data['lastUpdated'] = FieldValue.serverTimestamp();
    await _resources.add(data);
  }

  Future<void> deleteResource(String id) async {
    await _resources.doc(id).delete();
  }

  // USER MANAGEMENT
  Stream<QuerySnapshot<Map<String, dynamic>>> watchUsers() {
    return _users.snapshots();
  }

  Future<void> updateUserRole({
    required String userId,
    required int newRole,
  }) async {
    if (!validUserRoles.contains(newRole)) {
      throw ArgumentError('Please select a valid user role.');
    }

    await _users.doc(userId).update({
      'role': newRole,
    });
  }

  static String getRoleName(int role) {
    switch (role) {
      case touristRole:
        return 'Tourist';

      case travelAgencyRole:
        return 'Travel Agency';

      case tourismOfficerRole:
        return 'Tourism Officer';

      default:
        return 'Unknown Role';
    }
  }

  // VALIDATION

  void _validateCountry(dynamic country) {
    if (country is! String ||
        !southeastAsianCountries.contains(country)) {
      throw ArgumentError(
        'Please select a valid Southeast Asian country.',
      );
    }
  }
}

