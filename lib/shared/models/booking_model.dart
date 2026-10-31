import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String bookingid;
  final String touristuserid;
  final String agencyuserid;
  final String packageid;
  final String touristdisplayname;
  final Timestamp? traveldate;
  final double totalprice;
  final String currency;
  final String status; // pending / confirmed / cancelled
  final String paymentstatus; // unpaid / partial / paid
  final String? specialrequests;
  final List<Map<String, dynamic>> changehistory;
  final Timestamp? createtime;
  final Timestamp? updatetime;

  BookingModel({
    required this.bookingid,
    required this.touristuserid,
    required this.agencyuserid,
    required this.packageid,
    required this.touristdisplayname,
    this.traveldate,
    required this.totalprice,
    required this.currency,
    required this.status,
    required this.paymentstatus,
    this.specialrequests,
    required this.changehistory,
    this.createtime,
    this.updatetime,
  });

  factory BookingModel.fromMap(String id, Map<String, dynamic> data) {
    return BookingModel(
      bookingid: id,
      touristuserid: data['touristuserid'] ?? '',
      agencyuserid: data['agencyuserid'] ?? '',
      packageid: data['packageid'] ?? '',
      touristdisplayname: data['touristdisplayname'] ?? '',
      traveldate: data['traveldate'],
      totalprice: (data['totalprice'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'MYR',
      status: data['status'] ?? 'pending',
      paymentstatus: data['paymentstatus'] ?? 'unpaid',
      specialrequests: data['specialrequests'],
      changehistory: List<Map<String, dynamic>>.from(
        (data['changehistory'] ?? []).map((e) => Map<String, dynamic>.from(e)),
      ),
      createtime: data['createtime'],
      updatetime: data['updatetime'],
    );
  }
}
