import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String conversationid;
  final String touristuserid;
  final String staffuserid;
  final List<String> participantids;
  final String touristdisplayname;
  final String type; // agency / officer
  final String status; // new / in_progress / waiting_for_customer / confirmed
  final String? packageid;
  final String? priority;
  final Timestamp? followupat;
  final Map<String, dynamic>? customerpreferences;
  final Timestamp? createtime;
  final Timestamp? lastmessageat;

  ConversationModel({
    required this.conversationid,
    required this.touristuserid,
    required this.staffuserid,
    required this.participantids,
    required this.touristdisplayname,
    required this.type,
    required this.status,
    this.packageid,
    this.priority,
    this.followupat,
    this.customerpreferences,
    this.createtime,
    this.lastmessageat,
  });

  factory ConversationModel.fromMap(String id, Map<String, dynamic> data) {
    return ConversationModel(
      conversationid: id,
      touristuserid: data['touristuserid'] ?? '',
      staffuserid: data['staffuserid'] ?? '',
      participantids: List<String>.from(data['participantids'] ?? []),
      touristdisplayname: data['touristdisplayname'] ?? '',
      type: data['type'] ?? 'agency',
      status: data['status'] ?? 'new',
      packageid: data['packageid'],
      priority: data['priority'],
      followupat: data['followupat'],
      customerpreferences: data['customerpreferences'] == null
          ? null
          : Map<String, dynamic>.from(data['customerpreferences']),
      createtime: data['createtime'],
      lastmessageat: data['lastmessageat'],
    );
  }
}

class MessageModel {
  final String messageid;
  final String senderuserid;
  final String text;
  final Timestamp? sentat;

  MessageModel({required this.messageid, required this.senderuserid, required this.text, this.sentat});

  factory MessageModel.fromMap(String id, Map<String, dynamic> data) {
    return MessageModel(
      messageid: id,
      senderuserid: data['senderuserid'] ?? '',
      text: data['text'] ?? '',
      sentat: data['sentat'],
    );
  }
}
