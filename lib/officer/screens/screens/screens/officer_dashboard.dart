import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../shared/models/app_user.dart';

class OfficerDashboard extends StatelessWidget {
  final AppUser currentUser;

  const OfficerDashboard({
    super.key,
    required this.currentUser,
  });

  Stream<int> _count(String collection) {
    return FirebaseFirestore.instance
        .collection(collection)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Widget _statCard(
    String title,
    String collection,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<int>(
          stream: _count(collection),
          builder: (context, snapshot) {
            final count = snapshot.data;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 30),
                const SizedBox(height: 12),
                Text(
                  count?.toString() ?? '...',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(title),
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
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.35,
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
              _statCard(
                'Safety Zones',
                'danger_zones',
                Icons.map,
                Colors.red,
              ),
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
