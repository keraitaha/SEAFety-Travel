
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/officer_firebase_service.dart';

class OfficerSafetyMap extends StatefulWidget {
  const OfficerSafetyMap({super.key});

  @override
  State<OfficerSafetyMap> createState() => _OfficerSafetyMapState();
}

class _OfficerSafetyMapState extends State<OfficerSafetyMap> {
  final _service = OfficerFirebaseService();

  static const LatLng _initialPosition = LatLng(3.1390, 101.6869);

  String _country = 'Malaysia';

  Future<void> _addZone(LatLng position) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final radiusController = TextEditingController(text: '2');

    String zoneType = 'Danger';
    String risk = 'High';
    String country = _country;

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Safety Zone'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Zone name',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Enter a zone name'
                          : null,
                    ),
                    DropdownButtonFormField<String>(
                      value: zoneType,
                      decoration: const InputDecoration(
                        labelText: 'Zone type',
                      ),
                      items: ['Safe', 'Danger']
                          .map((v) => DropdownMenuItem(
                                value: v,
                                child: Text(v),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() {
                            zoneType = v;
                            risk = v == 'Safe' ? 'Low' : 'High';
                          });
                        }
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: risk,
                      decoration: const InputDecoration(
                        labelText: 'Risk level',
                      ),
                      items: ['Low', 'Medium', 'High', 'Critical']
                          .map((v) => DropdownMenuItem(
                                value: v,
                                child: Text(v),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => risk = v);
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: country,
                      decoration: const InputDecoration(labelText: 'Country'),
                      items: OfficerFirebaseService.southeastAsianCountries
                          .map((v) => DropdownMenuItem(
                                value: v,
                                child: Text(v),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => country = v);
                      },
                    ),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 3,
                    ),
                    TextFormField(
                      controller: radiusController,
                      decoration: const InputDecoration(
                        labelText: 'Radius (km)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        final value = double.tryParse(v ?? '');
                        if (value == null || value <= 0) {
                          return 'Enter a radius greater than zero';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Latitude: ${position.latitude.toStringAsFixed(5)}\n'
                      'Longitude: ${position.longitude.toStringAsFixed(5)}',
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                Navigator.pop(dialogContext, {
                  'name': nameController.text.trim(),
                  'zoneType': zoneType,
                  'risk': risk,
                  'country': country,
                  'description': descriptionController.text.trim(),
                  'latitude': position.latitude,
                  'longitude': position.longitude,
                  'radius': double.parse(radiusController.text.trim()),
                  'isActive': true,
                });
              },
              child: const Text('Save Zone'),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    descriptionController.dispose();
    radiusController.dispose();

    if (result == null) return;

    try {
      await _service.addZone(result);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Safety zone added.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add zone: $e')),
        );
      }
    }
  }

  Future<void> _deleteZone(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete safety zone?'),
        content: const Text('This will permanently delete the zone.'),
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

    if (confirm == true) {
      try {
        await _service.deleteZone(id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not delete zone: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _service.watchZones(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Could not load safety zones.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        final markers = <Marker>{};
        final circles = <Circle>{};

        for (final doc in docs) {
          final data = doc.data();

          final lat = (data['latitude'] as num?)?.toDouble();
          final lng = (data['longitude'] as num?)?.toDouble();

          if (lat == null || lng == null) continue;
          if (data['isActive'] == false) continue;

          final isSafe = data['zoneType'] == 'Safe';
          final color = isSafe ? Colors.green : Colors.red;
          final position = LatLng(lat, lng);
          final radiusKm =
              ((data['radius'] as num?)?.toDouble() ?? 2).clamp(0.1, 1000);

          markers.add(
            Marker(
              markerId: MarkerId(doc.id),
              position: position,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                isSafe
                    ? BitmapDescriptor.hueGreen
                    : BitmapDescriptor.hueRed,
              ),
              infoWindow: InfoWindow(
                title: data['name'] ?? 'Safety zone',
                snippet: '${data['zoneType'] ?? 'Unknown'} zone',
              ),
            ),
          );

          circles.add(
            Circle(
              circleId: CircleId(doc.id),
              center: position,
              radius: radiusKm * 1000,
              fillColor: color.withValues(alpha: 0.18),
              strokeColor: color,
              strokeWidth: 2,
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Long-press the map to add a safety zone.',
                    ),
                  ),
                  DropdownButton<String>(
                    value: _country,
                    items: OfficerFirebaseService.southeastAsianCountries
                        .map((v) => DropdownMenuItem(
                              value: v,
                              child: Text(v),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _country = v);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: _initialPosition,
                  zoom: 6,
                ),
                markers: markers,
                circles: circles,
                onLongPress: _addZone,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: true,
              ),
            ),
            SizedBox(
              height: 145,
              child: docs.isEmpty
                  ? const Center(child: Text('No safety zones yet.'))
                  : ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data();
                        final isSafe = data['zoneType'] == 'Safe';

                        return ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.circle,
                            color: isSafe ? Colors.green : Colors.red,
                          ),
                          title: Text(data['name'] ?? 'Unnamed zone'),
                          subtitle: Text(
                            '${data['country'] ?? ''} • '
                            '${data['zoneType'] ?? 'Unknown'}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deleteZone(doc.id),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
