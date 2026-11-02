import 'package:flutter/material.dart';
import 'package:seafety_travel/shared/models/tourist_data.dart';
import '../services/currency_service.dart';
import '../services/tourist_store.dart';
import '../widgets/tourist_ui.dart';
import 'tourist_chat_screen.dart';

class PackageDetailScreen extends StatefulWidget {
  final TouristStore store;
  final TravelPackage item;
  const PackageDetailScreen({super.key, required this.store, required this.item});

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  bool busy = false;
  String currency = 'MYR';
  Future<double>? converted;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) {
      final item = widget.store.packageById(widget.item.id);
      if (item == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Package details')),
          body: const Center(child: Text('Package no longer available.')),
        );
      }
      return _details(context, item);
    },
  );

  Widget _details(BuildContext context, TravelPackage item) {
    final place = widget.store.placeById(item.destinationId);
    final reviews = widget.store.reviews
        .where((review) => review.targetType == 'package' && review.targetId == item.id)
        .toList();
    return Scaffold(
      backgroundColor: TouristPalette.background,
      appBar: AppBar(title: const Text('Package details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DestinationArt(
            imageUrl: item.imageUrl.isEmpty ? (place?.imageUrl ?? '') : item.imageUrl,
            height: 185,
            icon: Icons.card_travel,
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: TouristPalette.navy),
          ),
          if (place != null)
            Text('${place.name} · ${locationOf(place)}', style: TextStyle(color: Colors.blueGrey.shade600)),
          const SizedBox(height: 12),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  money(item.price),
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: TouristPalette.navy),
                ),
                Text('Per package · ${item.durationDays} day(s) · ${item.availability}'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('View price in '),
                    DropdownButton<String>(
                      value: currency,
                      items: [
                        'MYR',
                        'EUR',
                        'USD',
                        'GBP',
                      ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          currency = v;
                          converted = v == 'MYR' ? null : CurrencyService().convertFromMyr(item.price, v);
                        });
                      },
                    ),
                  ],
                ),
                if (converted != null)
                  FutureBuilder<double>(
                    future: converted,
                    builder: (context, state) {
                      if (state.connectionState != ConnectionState.done) {
                        return const Text('Loading exchange rate…');
                      }
                      if (state.hasError) {
                        return const Text('Exchange rate unavailable. Price remains in MYR.');
                      }
                      return Text(
                        'Approximately $currency ${state.data!.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      );
                    },
                  ),
              ],
            ),
          ),
          const SectionTitle('The experience'),
          InfoCard(child: Text(item.description)),
          const SectionTitle('Included in this package'),
          InfoCard(
            child: Column(
              children: item.inclusions
                  .map(
                    (feature) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.check_circle_outline, color: TouristPalette.blue),
                      title: Text(feature),
                    ),
                  )
                  .toList(),
            ),
          ),
          SectionTitle('Reviews', subtitle: '${reviews.length} review(s)'),
          if (reviews.isEmpty) const InfoCard(child: Text('No published reviews yet.')),
          ...reviews.map(
            (review) => InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '★' * review.rating.clamp(0, 5).toInt() + '☆' * (5 - review.rating.clamp(0, 5)).toInt(),
                    style: const TextStyle(color: TouristPalette.blue, fontSize: 18),
                  ),
                  Text(review.comment),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          wideAction(
            'Add package to a trip',
            busy || item.availability == 'unavailable' ? null : () => _chooseTrip(),
            icon: Icons.add_circle_outline,
          ),
          const SizedBox(height: 8),
          wideAction(
            'Request a booking',
            busy || item.availability == 'unavailable' ? null : () => _requestBooking(),
            icon: Icons.event_available,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: busy ? null : _contactAgency,
            icon: const Icon(Icons.chat_outlined),
            label: const Text('Contact agency'),
          ),
        ],
      ),
    );
  }

  Future<void> _chooseTrip() async {
    if (widget.store.trips.isEmpty) {
      showNotice(context, 'Create a trip in My Trips first.');
      return;
    }
    final tripId = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Add to which trip?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            ...widget.store.trips.map(
              (trip) => ListTile(
                title: Text(trip.title),
                subtitle: Text('${trip.startDate} – ${trip.endDate}'),
                onTap: () => Navigator.pop(context, trip.id),
              ),
            ),
          ],
        ),
      ),
    );
    if (!mounted || tripId == null) return;
    final trip = widget.store.tripById(tripId);
    if (trip == null) return;
    if (trip.packageIds.contains(widget.item.id)) {
      showNotice(context, 'This package is already in the trip.');
      return;
    }
    await _execute(
      () => widget.store.saveTrip(trip.withPackages([...trip.packageIds, widget.item.id])),
      'Package added to your trip. No booking was created.',
    );
  }

  Future<void> _requestBooking() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (!mounted || date == null) return;
    final item = widget.store.packageById(widget.item.id);
    if (item == null) {
      showNotice(context, 'Package no longer available.');
      return;
    }
    await _execute(
      () => widget.store.requestBooking(item, date),
      'Booking request submitted. Payment was not processed.',
    );
  }

  Future<void> _contactAgency() async {
    await _execute(() async {
      final thread = await widget.store.openConversation(
        staffId: widget.item.agencyUserId,
        type: 'agency',
        packageId: widget.item.id,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TouristChatScreen(store: widget.store, thread: thread),
        ),
      );
    }, null);
  }

  Future<void> _execute(Future<void> Function() action, String? success) async {
    setState(() => busy = true);
    try {
      await action();
      if (mounted && success != null) showNotice(context, success);
    } catch (error) {
      if (mounted) showNotice(context, shortError(error));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
