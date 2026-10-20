import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createUserDoc({
    required String userid,
    required String firstname,
    required String lastname,
    required String email,
    String? country,
    String? gender,
    String? dob,
    int role = 0,
  }) async {
    await _db.collection('users').doc(userid).set({
      'firstname': firstname,
      'lastname': lastname,
      'email': email,
      'country': country,
      'gender': gender,
      'dob': dob,
      'role': role,
      'createtime': FieldValue.serverTimestamp(),
    });
  }

  Future<AppUser?> getUser(String userid) async {
    final doc = await _db.collection('users').doc(userid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.id, doc.data()!);
  }
}
