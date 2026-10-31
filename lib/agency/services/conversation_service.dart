import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:seafety_travel/shared/models/conversation_model.dart';

class ConversationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('conversations');

  // Enquiries assigned to this agency
  Stream<List<ConversationModel>> agencyConversations(String staffuserid) {
    return _col
        .where('staffuserid', isEqualTo: staffuserid)
        .where('type', isEqualTo: 'agency')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ConversationModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Stream<List<MessageModel>> messages(String conversationid) {
    return _col
        .doc(conversationid)
        .collection('messages')
        .orderBy('sentat', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => MessageModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> sendMessage({
    required String conversationid,
    required String senderuserid,
    required String text,
  }) async {
    final now = Timestamp.now();
    await _col.doc(conversationid).collection('messages').add({
      'senderuserid': senderuserid,
      'text': text,
      'sentat': now,
    });
    await _col.doc(conversationid).update({'lastmessageat': now});
  }

  Future<void> updateStatus(String conversationid, String status) async {
    await _col.doc(conversationid).update({'status': status});
  }

  Future<void> setFollowUp(String conversationid, DateTime when) async {
    await _col.doc(conversationid).update({
      'followupat': Timestamp.fromDate(when),
    });
  }

  Future<void> clearFollowUp(String conversationid) async {
    await _col.doc(conversationid).update({'followupat': null});
  }

  String statusLabel(String status) {
    switch (status) {
      case 'in_progress':
        return 'In progress';
      case 'waiting_for_customer':
        return 'Waiting for customer';
      case 'confirmed':
        return 'Confirmed';
      default:
        return 'New';
    }
  }
}
