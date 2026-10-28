import 'package:cloud_firestore/cloud_firestore.dart';

class OfficerFirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  CollectionReference<Map<String, dynamic>> get _destinations =>
      _db.collection('destinations');

  CollectionReference<Map<String, dynamic>> get _alerts =>
      _db.collection('safety_alerts');

  CollectionReference<Map<String, dynamic>> get _zones =>
      _db.collection('danger_zones');

  CollectionReference<Map<String, dynamic>> get _resources =>
      _db.collection('emergency_resources');

  Stream<QuerySnapshot<Map<String, dynamic>>> watchDestinations() {
    return _destinations.snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchAlerts() {
    return _alerts.snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchZones() {
    return _zones.snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchResources() {
    return _resources.snapshots();
  }

  Future<void> addDestination(Map<String, dynamic> data) async {
    _validateCountry(data['country']);
    data['lastUpdated'] = FieldValue.serverTimestamp();
    await _destinations.add(data);
  }

  Future<void> updateDestination(
    String id,
    Map<String, dynamic> data,
  ) async {
    _validateCountry(data['country']);
    data['lastUpdated'] = FieldValue.serverTimestamp();
    await _destinations.doc(id).update(data);
  }

  Future<void> deleteDestination(String id) async {
    await _destinations.doc(id).delete();
  }

  Future<void> addAlert(Map<String, dynamic> data) async {
    _validateCountry(data['country']);
    data['createdAt'] = FieldValue.serverTimestamp();
    await _alerts.add(data);
  }

  Future<void> updateAlert(
    String id,
    Map<String, dynamic> data,
  ) async {
    _validateCountry(data['country']);
    await _alerts.doc(id).update(data);
  }

  Future<void> deleteAlert(String id) async {
    await _alerts.doc(id).delete();
  }

  Future<void> addZone(Map<String, dynamic> data) async {
    _validateCountry(data['country']);
    data['createdAt'] = FieldValue.serverTimestamp();
    await _zones.add(data);
  }

  Future<void> deleteZone(String id) async {
    await _zones.doc(id).delete();
  }

  Future<void> addResource(Map<String, dynamic> data) async {
    _validateCountry(data['country']);
    data['lastUpdated'] = FieldValue.serverTimestamp();
    await _resources.add(data);
  }

  Future<void> deleteResource(String id) async {
    await _resources.doc(id).delete();
  }

  void _validateCountry(dynamic country) {
    if (country is! String ||
        !southeastAsianCountries.contains(country)) {
      throw ArgumentError('Please select a valid Southeast Asian country.');
    }
  }
}