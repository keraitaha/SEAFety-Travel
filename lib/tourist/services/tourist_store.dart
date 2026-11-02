import 'package:flutter/foundation.dart';
import 'package:seafety_travel/shared/models/tourist_data.dart';

abstract class TouristStore extends ChangeNotifier {
  TouristStore({required this.userId, required this.userName});

  final String userId;
  final String userName;
  final List<Place> destinations = [];
  final List<TravelPackage> packages = [];
  final List<SafetyAlert> alerts = [];
  final List<TravelReview> reviews = [];
  final List<Trip> trips = [];
  final List<ChatThread> threads = [];
  final Map<String, List<Activity>> activities = {};
  final Map<String, List<ChatMessage>> messages = {};
  String? officerId;
  String? loadError;
  bool loading = true;

  Place? placeById(String id) {
    for (final item in destinations) {
      if (item.id == id) return item;
    }
    return null;
  }

  TravelPackage? packageById(String id) {
    for (final item in packages) {
      if (item.id == id) return item;
    }
    return null;
  }

  Trip? tripById(String id) {
    for (final item in trips) {
      if (item.id == id) return item;
    }
    return null;
  }

  List<SafetyAlert> alertsFor(Place place) => alerts.where((alert) => alert.appliesTo(place)).toList();

  void changed() => notifyListeners();

  String? validatePlan(Trip trip) {
    final basic = TripMath.validate(trip);
    if (basic != null) return basic;
    if (placeById(trip.destinationId) == null) {
      return 'Select an available destination.';
    }
    for (final id in trip.packageIds.toSet()) {
      final item = packageById(id);
      if (item == null || item.destinationId != trip.destinationId || !item.price.isFinite || item.price < 0) {
        return 'Select valid packages for the trip destination.';
      }
    }
    for (final item in activities[trip.id] ?? <Activity>[]) {
      if (item.date.compareTo(trip.startDate) < 0 || item.date.compareTo(trip.endDate) > 0) {
        return 'Keep all itinerary activities within the trip dates.';
      }
    }
    return null;
  }

  Future<void> start();
  Future<void> saveTrip(Trip trip);
  Future<void> deleteTrip(String id);
  Future<void> saveActivity(String tripId, Activity item);
  Future<void> deleteActivity(String tripId, String activityId);
  Future<void> loadActivities(String tripId) async {}
  Future<void> loadMessages(String threadId) async {}
  Future<void> requestBooking(TravelPackage item, DateTime travelDate);
  Future<ChatThread> openConversation({required String staffId, required String type, String? packageId});
  Future<void> sendMessage(String threadId, String message);
}
