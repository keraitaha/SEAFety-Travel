import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String userid;
  final String firstname;
  final String lastname;
  final String email;
  final String? country;
  final String? gender;
  final String? dob;
  final int role;
  final Timestamp? createtime;

  AppUser({
    required this.userid,
    required this.firstname,
    required this.lastname,
    required this.email,
    this.country,
    this.gender,
    this.dob,
    required this.role,
    this.createtime,
  });

  String get fullName => '$firstname $lastname';

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      userid: id,
      firstname: data['firstname'] ?? '',
      lastname: data['lastname'] ?? '',
      email: data['email'] ?? '',
      country: data['country'],
      gender: data['gender'],
      dob: data['dob'],
      role: data['role'] ?? 0,
      createtime: data['createtime'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstname': firstname,
      'lastname': lastname,
      'email': email,
      'country': country,
      'gender': gender,
      'dob': dob,
      'role': role,
      'createtime': createtime ?? FieldValue.serverTimestamp(),
    };
  }

  static String roleLabel(int role) {
    switch (role) {
      case 1:
        return 'Travel Agency';
      case 2:
        return 'Tourism Officer';
      default:
        return 'Tourist';
    }
  }
}
