import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:seafety_travel/shared/models/package_model.dart';

class PackageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('packages');

  // Live list of agency's packages
  Stream<List<PackageModel>> myPackages(String agencyuserid) {
    return _col
        .where('agencyuserid', isEqualTo: agencyuserid)
        .snapshots()
        .map((snap) => snap.docs.map((d) => PackageModel.fromMap(d.id, d.data())).toList());
  }

  Future<void> addPackage({
    required String agencyuserid,
    required String destinationid,
    required String title,
    required String description,
    required String imageurl,
    required double price,
    required int durationdays,
    required List<String> inclusions,
    required String availability,
    required bool published,
  }) async {
    await _col.add({
      'agencyuserid': agencyuserid,
      'destinationid': destinationid,
      'title': title,
      'description': description,
      'imageurl': imageurl,
      'price': price,
      'currency': 'MYR',
      'durationdays': durationdays,
      'inclusions': inclusions,
      'availability': availability,
      'published': published,
      'updatetime': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePackage({
    required String packageid,
    required String destinationid,
    required String title,
    required String description,
    required String imageurl,
    required double price,
    required int durationdays,
    required List<String> inclusions,
    required String availability,
    required bool published,
  }) async {
    await _col.doc(packageid).update({
      'destinationid': destinationid,
      'title': title,
      'description': description,
      'imageurl': imageurl,
      'price': price,
      'currency': 'MYR',
      'durationdays': durationdays,
      'inclusions': inclusions,
      'availability': availability,
      'published': published,
      'updatetime': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePackage(String packageid) async {
    await _col.doc(packageid).delete();
  }
}
