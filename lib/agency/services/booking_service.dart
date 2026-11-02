import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:seafety_travel/shared/models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('bookings');

  // Live list of bookings for this agency
  Stream<List<BookingModel>> agencyBookings(String agencyuserid) {
    return _col
        .where('agencyuserid', isEqualTo: agencyuserid)
        .snapshots()
        .map((snap) => snap.docs.map((d) => BookingModel.fromMap(d.id, d.data())).toList());
  }

  Future<void> updateStatus({required String bookingid, required String status, required String summary}) async {
    await _col.doc(bookingid).update({
      'status': status,
      'changehistory': FieldValue.arrayUnion([
        {'summary': summary, 'changedat': Timestamp.now()},
      ]),
      'updatetime': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePaymentStatus({
    required String bookingid,
    required String paymentstatus,
    required String summary,
  }) async {
    await _col.doc(bookingid).update({
      'paymentstatus': paymentstatus,
      'changehistory': FieldValue.arrayUnion([
        {'summary': summary, 'changedat': Timestamp.now()},
      ]),
      'updatetime': FieldValue.serverTimestamp(),
    });
  }
}
