import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:seafety_travel/shared/models/app_user.dart';

class OfficerDashboard extends StatelessWidget {
  final AppUser currentUser;

  const OfficerDashboard({super.key, required this.currentUser});

  // Get the number of documents in a Firestore collection.
  Stream<int> _count(String collection) {
    return FirebaseFirestore.instance
        .collection(collection)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Dashboard statistic card.
  Widget _statCard(
    String title,
    String collection,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.all(6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: StreamBuilder<int>(
          stream: _count(collection),
          builder: (context, snapshot) {
            final count = snapshot.data;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 28),

                const SizedBox(height: 8),

                Text(
                  count?.toString() ?? '...',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),

                const SizedBox(height: 4),

                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome message
          Text(
            'Welcome, ${currentUser.firstname}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),

          const SizedBox(height: 8),

          const Text(
            'Manage destination information, safety alerts, '
            'map zones, and emergency resources.',
          ),

          const SizedBox(height: 20),

          // Dashboard statistics
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),

            // Give each card more vertical space.
            childAspectRatio: 1.15,

            children: [
              _statCard(
                'Destinations',
                'destinations',
                Icons.place,
                Colors.blue,
              ),

              _statCard(
                'Safety Alerts',
                'safety_alerts',
                Icons.notifications_active,
                Colors.orange,
              ),

              _statCard('Safety Zones', 'danger_zones', Icons.map, Colors.red),

              _statCard(
                'Emergency Resources',
                'emergency_resources',
                Icons.emergency,
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
