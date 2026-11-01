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
  final OfficerFirebaseService _service = OfficerFirebaseService();

  static const LatLng _initialPosition = LatLng(3.1390, 101.6869);

  String _country = 'Malaysia';

  // Add a new safety zone
  Future<void> _addZone(LatLng position) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return AddSafetyZoneDialog(
          position: position,
          initialCountry: _country,
        );
      },
    );

    if (result == null || !mounted) return;

    try {
      await _service.addZone(result);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Safety zone added successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not add safety zone: $e'),
        ),
      );
    }
  }

  // Delete a safety zone
  Future<void> _deleteZone(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete safety zone?'),
          content: const Text(
            'This will permanently delete the selected zone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await _service.deleteZone(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Safety zone deleted.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete zone: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _service.watchZones(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Could not load safety zones.'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final docs = snapshot.data!.docs;

        final markers = <Marker>{};
        final circles = <Circle>{};

        // Generate map markers and circles from Firestore
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
          ((data['radius'] as num?)?.toDouble() ?? 2.0)
              .clamp(0.1, 1000.0);

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
            // Country selector
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
                    items: OfficerFirebaseService
                        .southeastAsianCountries
                        .map((country) {
                      return DropdownMenuItem<String>(
                        value: country,
                        child: Text(country),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _country = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),

            // Google Map
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

            // Safety zone list
            SizedBox(
              height: 145,
              child: docs.isEmpty
                  ? const Center(
                child: Text('No safety zones yet.'),
              )
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
                      color: isSafe
                          ? Colors.green
                          : Colors.red,
                    ),
                    title: Text(
                      data['name'] ?? 'Unnamed zone',
                    ),
                    subtitle: Text(
                      '${data['country'] ?? ''} • '
                          '${data['zoneType'] ?? 'Unknown'}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                      ),
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

// ======================================================
// ADD SAFETY ZONE DIALOG
// ======================================================

class AddSafetyZoneDialog extends StatefulWidget {
  final LatLng position;
  final String initialCountry;

  const AddSafetyZoneDialog({
    super.key,
    required this.position,
    required this.initialCountry,
  });

  @override
  State<AddSafetyZoneDialog> createState() =>
      _AddSafetyZoneDialogState();
}

class _AddSafetyZoneDialogState
    extends State<AddSafetyZoneDialog> {

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _radiusController = TextEditingController(text: '2');

  String _zoneType = 'Danger';
  String _risk = 'High';

  late String _country;

  @override
  void initState() {
    super.initState();

    _country = widget.initialCountry;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _radiusController.dispose();

    super.dispose();
  }

  // Save zone information and return it to the map
  void _saveZone() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final radius = double.tryParse(
      _radiusController.text.trim(),
    );

    if (radius == null || !radius.isFinite || radius <= 0) {
      return;
    }

    Navigator.pop(context, {
      'name': _nameController.text.trim(),
      'zoneType': _zoneType,
      'risk': _risk,
      'country': _country,
      'description': _descriptionController.text.trim(),
      'latitude': widget.position.latitude,
      'longitude': widget.position.longitude,
      'radius': radius,
      'isActive': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Safety Zone'),

      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // Zone name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Zone name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Enter a zone name';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Zone type
                DropdownButtonFormField<String>(
                  value: _zoneType,
                  decoration: const InputDecoration(
                    labelText: 'Zone type',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Safe', 'Danger'].map((value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _zoneType = value;

                      _risk = value == 'Safe'
                          ? 'Low'
                          : 'High';
                    });
                  },
                ),

                const SizedBox(height: 12),

                // Risk level
                DropdownButtonFormField<String>(
                  value: _risk,
                  decoration: const InputDecoration(
                    labelText: 'Risk level',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    'Low',
                    'Medium',
                    'High',
                    'Critical',
                  ].map((value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _risk = value;
                      });
                    }
                  },
                ),

                const SizedBox(height: 12),

                // Country
                DropdownButtonFormField<String>(
                  value: _country,
                  decoration: const InputDecoration(
                    labelText: 'Country',
                    border: OutlineInputBorder(),
                  ),
                  items: OfficerFirebaseService
                      .southeastAsianCountries
                      .map((country) {
                    return DropdownMenuItem<String>(
                      value: country,
                      child: Text(country),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _country = value;
                      });
                    }
                  },
                ),

                const SizedBox(height: 12),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 12),

                // Radius
                TextFormField(
                  controller: _radiusController,
                  decoration: const InputDecoration(
                    labelText: 'Radius (km)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                  const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    final radius = double.tryParse(
                      value ?? '',
                    );

                    if (radius == null ||
                        !radius.isFinite ||
                        radius <= 0) {
                      return 'Enter a valid radius greater than zero';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Selected coordinates
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected Location',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Latitude: '
                            '${widget.position.latitude.toStringAsFixed(5)}',
                      ),

                      Text(
                        'Longitude: '
                            '${widget.position.longitude.toStringAsFixed(5)}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),

        FilledButton(
          onPressed: _saveZone,
          child: const Text('Save Zone'),
        ),
      ],
    );
  }
}
