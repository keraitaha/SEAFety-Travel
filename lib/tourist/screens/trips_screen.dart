import 'package:flutter/material.dart';
import 'package:seafety_travel/shared/models/tourist_data.dart';
import '../services/tourist_store.dart';
import '../widgets/tourist_ui.dart';
import 'trip_form_dialog.dart';
import 'trip_detail_screen.dart';

class TripsScreen extends StatelessWidget {
  final TouristStore store;
  const TripsScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final trips = [...store.trips]
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: TouristPalette.ice,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            children: [
              Icon(Icons.luggage, color: TouristPalette.navy, size: 32),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Your journey, organized.\nPlan the trip. Know the cost.',
                  style: TextStyle(
                    color: TouristPalette.navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('My trips'),
        wideAction('Create a trip', () => _edit(context), icon: Icons.add),
        const SizedBox(height: 16),
        if (trips.isEmpty)
          const InfoCard(
            child: Column(
              children: [
                Icon(Icons.map_outlined, size: 42, color: TouristPalette.blue),
                SizedBox(height: 8),
                Text('No trips planned yet.'),
                Text('Create a trip to save packages and plan your itinerary.'),
              ],
            ),
          ),
        ...trips.map((trip) {
          final place = store.placeById(trip.destinationId);
          final total = TripMath.total(
            trip,
            store.packages,
            store.activities[trip.id] ?? [],
          );
          return InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        trip.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: TouristPalette.navy,
                        ),
                      ),
                    ),
                    Chip(label: Text(trip.status)),
                  ],
                ),
                Text(
                  place?.name ?? 'Destination unavailable',
                  style: TextStyle(color: Colors.blueGrey.shade600),
                ),
                const SizedBox(height: 10),
                LabelValue(
                  icon: Icons.date_range,
                  label: 'Travel dates',
                  value: '${trip.startDate} to ${trip.endDate}',
                ),
                LabelValue(
                  icon: Icons.payments_outlined,
                  label: 'Estimated cost / budget',
                  value: '${money(total)} / ${money(trip.budget)}',
                ),
                if (total > trip.budget)
                  const Text(
                    'Estimated cost exceeds your budget.',
                    style: TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const Divider(),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 4,
                  children: [
                    TextButton(
                      onPressed: () => _edit(context, trip),
                      child: const Text('Edit'),
                    ),
                    TextButton(
                      onPressed: () => _delete(context, trip),
                      child: const Text('Delete'),
                    ),
                    FilledButton.tonal(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TripDetailScreen(store: store, tripId: trip.id),
                        ),
                      ),
                      child: const Text('Open trip'),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Future<void> _edit(BuildContext context, [Trip? trip]) async {
    final saved = await showDialog<Trip>(
      context: context,
      builder: (_) =>
          TripFormDialog(existing: trip, places: store.destinations),
    );
    if (saved == null) return;
    try {
      await store.saveTrip(saved);
      if (context.mounted) showNotice(context, 'Trip saved.');
    } catch (error) {
      if (context.mounted) showNotice(context, shortError(error));
    }
  }

  Future<void> _delete(BuildContext context, Trip trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete trip?'),
        content: Text('Remove ${trip.title} and all its itinerary activities?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await store.deleteTrip(trip.id);
      if (context.mounted) showNotice(context, 'Trip deleted.');
    } catch (error) {
      if (context.mounted) showNotice(context, shortError(error));
    }
  }
}
