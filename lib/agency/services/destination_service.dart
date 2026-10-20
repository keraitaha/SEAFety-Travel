import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/destination_model.dart';

// Destinations are read-only for the agency (managed by the Tourism Officer).
class DestinationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<DestinationModel>> publishedDestinations() {
    return _db
        .collection('destinations')
        .where('published', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => DestinationModel.fromMap(d.id, d.data()))
            .toList());
  }

  Future<DestinationModel?> getDestination(String destinationid) async {
    final doc = await _db.collection('destinations').doc(destinationid).get();
    if (!doc.exists) return null;
    return DestinationModel.fromMap(doc.id, doc.data()!);
  }
}
