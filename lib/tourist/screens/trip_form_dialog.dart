import 'package:flutter/material.dart';
import 'package:seafety_travel/shared/models/tourist_data.dart';

class TripFormDialog extends StatefulWidget {
  final Trip? existing;
  final List<Place> places;
  const TripFormDialog({super.key, this.existing, required this.places});

  @override
  State<TripFormDialog> createState() => _TripFormDialogState();
}

class _TripFormDialogState extends State<TripFormDialog> {
  late final TextEditingController name;
  late final TextEditingController budget;
  late String destinationId;
  late String status;
  late DateTime start;
  late DateTime end;
  String? error;

  @override
  void initState() {
    super.initState();
    final trip = widget.existing;
    name = TextEditingController(text: trip?.title ?? '');
    budget = TextEditingController(text: trip?.budget.toStringAsFixed(2) ?? '');
    destinationId = trip?.destinationId ?? (widget.places.isNotEmpty ? widget.places.first.id : '');
    status = trip?.status ?? 'planned';
    start = DateTime.tryParse(trip?.startDate ?? '') ?? DateTime.now();
    end = DateTime.tryParse(trip?.endDate ?? '') ?? start.add(const Duration(days: 1));
  }

  @override
  void dispose() {
    name.dispose();
    budget.dispose();
    super.dispose();
  }

  String _iso(DateTime date) => date.toIso8601String().substring(0, 10);

  Future<void> _chooseDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? start : end,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    setState(() {
      if (isStart) {
        start = date;
        if (end.isBefore(start)) end = start;
      } else {
        end = date;
      }
    });
  }

  void _save() {
    final trip = Trip(
      id: widget.existing?.id ?? '',
      title: name.text,
      destinationId: destinationId,
      startDate: _iso(start),
      endDate: _iso(end),
      budget: double.tryParse(budget.text.trim()) ?? double.nan,
      status: status,
      packageIds: widget.existing?.packageIds ?? [],
    );
    final message = TripMath.validate(trip);
    if (message != null) {
      setState(() => error = message);
      return;
    }
    Navigator.pop(context, trip);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.existing == null ? 'Create trip' : 'Edit trip'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Trip name'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: widget.places.any((place) => place.id == destinationId) ? destinationId : null,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Destination'),
            items: widget.places
                .map(
                  (place) => DropdownMenuItem(
                    value: place.id,
                    child: Text(place.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => destinationId = value ?? ''),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: budget,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Budget (MYR)'),
          ),
          const SizedBox(height: 10),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Start: ${_iso(start)}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _chooseDate(true),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('End: ${_iso(end)}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _chooseDate(false),
          ),
          DropdownButtonFormField<String>(
            initialValue: status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: [
              'planned',
              'ongoing',
              'completed',
            ].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
            onChanged: (value) => setState(() => status = value ?? 'planned'),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(error!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: _save, child: const Text('Save')),
    ],
  );
}
