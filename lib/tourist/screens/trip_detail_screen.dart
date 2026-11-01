import 'package:flutter/material.dart';
import 'package:seafety_travel/shared/models/tourist_data.dart';
import '../services/tourist_store.dart';
import '../widgets/tourist_ui.dart';
import 'package_detail_screen.dart';

class TripDetailScreen extends StatefulWidget {
  final TouristStore store;
  final String tripId;
  const TripDetailScreen({
    super.key,
    required this.store,
    required this.tripId,
  });

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  @override
  void initState() {
    super.initState();
    widget.store.loadActivities(widget.tripId).catchError((Object error) {
      if (mounted) showNotice(context, shortError(error));
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) {
      final trip = widget.store.tripById(widget.tripId);
      if (trip == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Trip')),
          body: const Center(child: Text('Trip no longer exists.')),
        );
      }
      final activities = [...(widget.store.activities[trip.id] ?? <Activity>[])]
        ..sort((a, b) {
          final byDate = a.date.compareTo(b.date);
          return byDate != 0 ? byDate : a.time.compareTo(b.time);
        });
      final total = TripMath.total(trip, widget.store.packages, activities);
      return Scaffold(
        backgroundColor: TouristPalette.background,
        appBar: AppBar(title: Text(trip.title)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.store.placeById(trip.destinationId)?.name ??
                        'Destination unavailable',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: TouristPalette.navy,
                    ),
                  ),
                  Text('${trip.startDate} – ${trip.endDate} · ${trip.status}'),
                  const Divider(height: 24),
                  Text(
                    money(total),
                    style: const TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.w800,
                      color: TouristPalette.navy,
                    ),
                  ),
                  Text('Estimated cost of trip · budget ${money(trip.budget)}'),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: trip.budget <= 0
                        ? 0.0
                        : (total / trip.budget).clamp(0.0, 1.0).toDouble(),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  if (total > trip.budget)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Over your planned budget',
                        style: TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SectionTitle('Selected packages'),
            if (trip.packageIds.isEmpty)
              const InfoCard(child: Text('No packages added yet.')),
            ...trip.packageIds.map((id) {
              final item = widget.store.packageById(id);
              return InfoCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item?.title ?? 'Package no longer available',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            item == null
                                ? 'Check with agency'
                                : money(item.price),
                          ),
                        ],
                      ),
                    ),
                    if (item != null)
                      IconButton(
                        tooltip: 'View package',
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PackageDetailScreen(
                              store: widget.store,
                              item: item,
                            ),
                          ),
                        ),
                      ),
                    IconButton(
                      tooltip: 'Remove from plan',
                      icon: const Icon(Icons.close),
                      onPressed: () => _removePackage(trip, id),
                    ),
                  ],
                ),
              );
            }),
            OutlinedButton.icon(
              onPressed: () => _addPackage(trip),
              icon: const Icon(Icons.add),
              label: const Text('Add a package'),
            ),
            const SectionTitle(
              'Daily itinerary',
              subtitle: 'Extra costs not included in packages',
            ),
            wideAction(
              'Add activity',
              () => _editActivity(trip),
              icon: Icons.add,
            ),
            const SizedBox(height: 12),
            if (activities.isEmpty)
              const InfoCard(
                child: Text('No activities yet. Add the first stop.'),
              ),
            ...activities.map(
              (item) => InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${item.date}${item.time.isEmpty ? '' : ' · ${item.time}'}',
                    ),
                    Text('Extra cost: ${money(item.cost)}'),
                    if (item.notes.isNotEmpty) Text(item.notes),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _editActivity(trip, item),
                          child: const Text('Edit'),
                        ),
                        TextButton(
                          onPressed: () => _deleteActivity(trip.id, item.id),
                          child: const Text('Remove'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    },
  );

  Future<void> _removePackage(Trip trip, String packageId) async {
    try {
      await widget.store.saveTrip(
        trip.withPackages(
          trip.packageIds.where((id) => id != packageId).toList(),
        ),
      );
      if (mounted) {
        showNotice(
          context,
          'Package removed from trip, not cancelled with agency.',
        );
      }
    } catch (error) {
      if (mounted) showNotice(context, shortError(error));
    }
  }

  Future<void> _addPackage(Trip trip) async {
    final available = widget.store.packages
        .where(
          (item) =>
              item.destinationId == trip.destinationId &&
              !trip.packageIds.contains(item.id) &&
              item.availability != 'unavailable',
        )
        .toList();
    if (available.isEmpty) {
      showNotice(context, 'No additional packages for this destination.');
      return;
    }
    final id = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select package',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...available.map(
              (item) => ListTile(
                title: Text(item.title),
                subtitle: Text(money(item.price)),
                onTap: () => Navigator.pop(context, item.id),
              ),
            ),
          ],
        ),
      ),
    );
    if (id == null) return;
    try {
      await widget.store.saveTrip(trip.withPackages([...trip.packageIds, id]));
    } catch (error) {
      if (mounted) showNotice(context, shortError(error));
    }
  }

  Future<void> _editActivity(Trip trip, [Activity? existing]) async {
    final item = await showDialog<Activity>(
      context: context,
      builder: (_) => ActivityFormDialog(trip: trip, existing: existing),
    );
    if (item == null) return;
    try {
      await widget.store.saveActivity(trip.id, item);
      if (mounted) showNotice(context, 'Activity saved.');
    } catch (error) {
      if (mounted) showNotice(context, shortError(error));
    }
  }

  Future<void> _deleteActivity(String tripId, String itemId) async {
    try {
      await widget.store.deleteActivity(tripId, itemId);
      if (mounted) showNotice(context, 'Activity removed.');
    } catch (error) {
      if (mounted) showNotice(context, shortError(error));
    }
  }
}

class ActivityFormDialog extends StatefulWidget {
  final Trip trip;
  final Activity? existing;
  const ActivityFormDialog({super.key, required this.trip, this.existing});

  @override
  State<ActivityFormDialog> createState() => _ActivityFormDialogState();
}

class _ActivityFormDialogState extends State<ActivityFormDialog> {
  late final TextEditingController name;
  late final TextEditingController cost;
  late final TextEditingController notes;
  late DateTime date;
  TimeOfDay? activityTime;
  String? error;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.existing?.name ?? '');
    cost = TextEditingController(
      text: widget.existing?.cost.toStringAsFixed(2) ?? '0',
    );
    notes = TextEditingController(text: widget.existing?.notes ?? '');
    final first = DateTime.parse(widget.trip.startDate);
    final last = DateTime.parse(widget.trip.endDate);
    final original = DateTime.tryParse(widget.existing?.date ?? '') ?? first;
    date = original.isBefore(first)
        ? first
        : (original.isAfter(last) ? last : original);
    final saved = widget.existing?.time ?? '';
    final parts = saved.split(':');
    if (parts.length == 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null &&
          minute != null &&
          hour >= 0 &&
          minute >= 0 &&
          hour < 24 &&
          minute < 60) {
        activityTime = TimeOfDay(hour: hour, minute: minute);
      }
    }
  }

  @override
  void dispose() {
    name.dispose();
    cost.dispose();
    notes.dispose();
    super.dispose();
  }

  String get iso => date.toIso8601String().substring(0, 10);
  String get clock => activityTime == null
      ? ''
      : '${activityTime!.hour.toString().padLeft(2, '0')}:${activityTime!.minute.toString().padLeft(2, '0')}';

  void _save() {
    final price = double.tryParse(cost.text.trim());
    if (name.text.trim().isEmpty ||
        price == null ||
        !price.isFinite ||
        price < 0) {
      setState(() => error = 'Enter a name and a valid non-negative cost.');
      return;
    }
    Navigator.pop(
      context,
      Activity(
        id: widget.existing?.id ?? '',
        name: name.text.trim(),
        date: iso,
        time: clock,
        cost: price,
        notes: notes.text.trim(),
        order: widget.existing?.order ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.existing == null ? 'Add activity' : 'Edit activity'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Activity'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: cost,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Additional cost (MYR)',
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            title: Text('Date: $iso'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final chosen = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime.parse(widget.trip.startDate),
                lastDate: DateTime.parse(widget.trip.endDate),
              );
              if (chosen != null) setState(() => date = chosen);
            },
          ),
          ListTile(
            title: Text(clock.isEmpty ? 'Time: optional' : 'Time: $clock'),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final selected = await showTimePicker(
                context: context,
                initialTime:
                    activityTime ?? const TimeOfDay(hour: 9, minute: 0),
              );
              if (selected != null) setState(() => activityTime = selected);
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: notes,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
          ),
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Save')),
    ],
  );
}
