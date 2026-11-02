import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:seafety_travel/shared/models/tourist_data.dart';
import 'tourist_store.dart';

class FirestoreTouristStore extends TouristStore {
  FirestoreTouristStore({required super.userId, required super.userName, FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final Set<String> _watchedThreads = {};

  void _failed(Object error) {
    loadError = 'Some live data could not load. Check Firestore access rules.';
    loading = false;
    changed();
  }

  @override
  Future<void> start() async {
    _subscriptions.add(
      _db.collection('destinations').where('published', isEqualTo: true).snapshots().listen((result) {
        destinations
          ..clear()
          ..addAll(result.docs.map((doc) => Place.fromMap(doc.id, doc.data())));
        loading = false;
        changed();
      }, onError: _failed),
    );
    _subscriptions.add(
      _db.collection('packages').where('published', isEqualTo: true).snapshots().listen((result) {
        packages
          ..clear()
          ..addAll(result.docs.map((doc) => TravelPackage.fromMap(doc.id, doc.data())));
        loading = false;
        changed();
      }, onError: _failed),
    );
    _subscriptions.add(
      _db.collection('safety_alerts').snapshots().listen((result) {
        alerts
          ..clear()
          ..addAll(
            result.docs.map((doc) {
              final data = doc.data();
              return SafetyAlert.fromMap(doc.id, data, (data['updatetime'] as Timestamp?)?.toDate());
            }),
          );
        changed();
      }, onError: _failed),
    );
    _subscriptions.add(
      _db.collection('reviews').snapshots().listen((result) {
        reviews
          ..clear()
          ..addAll(result.docs.map((doc) => TravelReview.fromMap(doc.data())));
        changed();
      }, onError: _failed),
    );
    _subscriptions.add(
      _db.collection('trips').where('userid', isEqualTo: userId).snapshots().listen((result) {
        trips
          ..clear()
          ..addAll(result.docs.map((doc) => Trip.fromMap(doc.id, doc.data())));
        for (final trip in trips) {
          loadActivities(trip.id).catchError((Object error) => _failed(error));
        }
        changed();
      }, onError: _failed),
    );
    _subscriptions.add(
      _db.collection('conversations').where('touristuserid', isEqualTo: userId).snapshots().listen((result) {
        threads
          ..clear()
          ..addAll(
            result.docs.map(
              (doc) => ChatThread(
                id: doc.id,
                staffId: '${doc.data()['staffuserid'] ?? ''}',
                type: '${doc.data()['type'] ?? 'agency'}',
                packageId: doc.data()['packageid'] as String?,
                status: '${doc.data()['status'] ?? 'new'}',
              ),
            ),
          );
        changed();
      }, onError: _failed),
    );
    try {
      final staff = await _db.collection('users').where('role', isEqualTo: 2).limit(1).get();
      if (staff.docs.isNotEmpty) officerId = staff.docs.first.id;
      changed();
    } catch (_) {
      // Officer contact remains unavailable until a staff account exists.
    }
  }

  @override
  Future<void> saveTrip(Trip trip) async {
    if (trip.id.isNotEmpty) await loadActivities(trip.id);
    final error = validatePlan(trip);
    if (error != null) throw FormatException(error);
    final data = {...trip.toMap(userId), 'updatetime': FieldValue.serverTimestamp()};
    if (trip.id.isEmpty) {
      data['createtime'] = FieldValue.serverTimestamp();
      await _db.collection('trips').add(data);
    } else {
      await _db.collection('trips').doc(trip.id).update(data);
    }
  }

  @override
  Future<void> deleteTrip(String id) async {
    final reference = _db.collection('trips').doc(id);
    final children = await reference.collection('itineraryitems').get();
    for (final doc in children.docs) {
      await doc.reference.delete();
    }
    await reference.delete();
    activities.remove(id);
    changed();
  }

  @override
  Future<void> loadActivities(String tripId) async {
    final result = await _db.collection('trips').doc(tripId).collection('itineraryitems').get();
    activities[tripId] = result.docs.map((doc) => Activity.fromMap(doc.id, doc.data())).toList();
    changed();
  }

  @override
  Future<void> saveActivity(String tripId, Activity item) async {
    final trip = tripById(tripId);
    if (trip == null) throw StateError('Trip not found.');
    if (item.name.trim().isEmpty ||
        !item.cost.isFinite ||
        item.cost < 0 ||
        !TripMath.validDate(item.date) ||
        item.date.compareTo(trip.startDate) < 0 ||
        item.date.compareTo(trip.endDate) > 0) {
      throw const FormatException('Enter a name, valid trip date and non-negative cost.');
    }
    final collection = _db.collection('trips').doc(tripId).collection('itineraryitems');
    if (item.id.isEmpty) {
      await collection.add(item.toMap());
    } else {
      await collection.doc(item.id).update(item.toMap());
    }
    await loadActivities(tripId);
  }

  @override
  Future<void> deleteActivity(String tripId, String activityId) async {
    await _db.collection('trips').doc(tripId).collection('itineraryitems').doc(activityId).delete();
    await loadActivities(tripId);
  }

  @override
  Future<void> requestBooking(TravelPackage item, DateTime travelDate) async {
    if (item.agencyUserId.isEmpty || item.availability == 'unavailable') {
      throw StateError('This package is not available for booking.');
    }
    await _db.collection('bookings').add({
      'touristuserid': userId,
      'agencyuserid': item.agencyUserId,
      'packageid': item.id,
      'touristdisplayname': userName,
      'traveldate': Timestamp.fromDate(travelDate),
      'totalprice': item.price,
      'currency': 'MYR',
      'status': 'pending',
      'paymentstatus': 'unpaid',
      'specialrequests': '',
      'changehistory': [],
      'createtime': FieldValue.serverTimestamp(),
      'updatetime': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<ChatThread> openConversation({required String staffId, required String type, String? packageId}) async {
    if (staffId.isEmpty) throw StateError('No staff member available.');
    for (final thread in threads) {
      if (thread.staffId == staffId && thread.type == type && thread.packageId == packageId) {
        return thread;
      }
    }
    final now = Timestamp.now();
    final created = await _db.collection('conversations').add({
      'touristuserid': userId,
      'staffuserid': staffId,
      'participantids': [userId, staffId],
      'touristdisplayname': userName,
      'type': type,
      'status': type == 'agency' ? 'new' : 'open',
      'packageid': ?packageId,
      'createtime': now,
      'lastmessageat': now,
    });
    return ChatThread(id: created.id, staffId: staffId, type: type, packageId: packageId);
  }

  @override
  Future<void> loadMessages(String threadId) async {
    if (!_watchedThreads.add(threadId)) return;
    final sub = _db
        .collection('conversations')
        .doc(threadId)
        .collection('messages')
        .orderBy('sentat')
        .snapshots()
        .listen((snap) {
          messages[threadId] = snap.docs
              .map(
                (doc) => ChatMessage(
                  senderId: '${doc.data()['senderuserid'] ?? ''}',
                  text: '${doc.data()['text'] ?? ''}',
                  createdAt: (doc.data()['sentat'] as Timestamp?)?.toDate() ?? DateTime.now(),
                ),
              )
              .toList();
          changed();
        }, onError: _failed);
    _subscriptions.add(sub);
  }

  @override
  Future<void> sendMessage(String threadId, String message) async {
    if (message.trim().isEmpty) return;
    final now = Timestamp.now();
    final doc = _db.collection('conversations').doc(threadId);
    await doc.collection('messages').add({'senderuserid': userId, 'text': message.trim(), 'sentat': now});
    await doc.update({'lastmessageat': now});
  }

  @override
  void dispose() {
    for (final item in _subscriptions) {
      item.cancel();
    }
    super.dispose();
  }
}
