import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
 
import '../services/officer_firebase_service.dart';
 
class OfficerAlerts extends StatefulWidget {
  const OfficerAlerts({super.key});
 
  @override
  State<OfficerAlerts> createState() => _OfficerAlertsState();
}
 
class _OfficerAlertsState extends State<OfficerAlerts> {
  final _service = OfficerFirebaseService();
 
  // Option lists for the dropdowns. Keeping them in one place means the
  // initial value and the items can never get out of sync.
  static const List<String> _types = [
    'Travel Advisory',
    'Weather',
    'Security',
    'Transport',
    'Natural Disaster',
    'Other',
  ];
  static const List<String> _risks = ['Low', 'Medium', 'High', 'Critical'];
 
  // 'Published' is included because existing alerts already use it.
  // Remove it if you do not want officers to pick it.
  static const List<String> _statuses = [
    'Active',
    'Published',
    'Resolved',
    'Expired',
  ];
 
  /// Returns [value] if it is one of [options], otherwise [fallback].
  /// Prevents the DropdownButton assertion when Firestore holds a value
  /// that is not in the list.
  String _pick(dynamic value, List<String> options, String fallback) {
    return value is String && options.contains(value) ? value : fallback;
  }
 
  Future<void> _showForm({String? id, Map<String, dynamic>? existing}) async {
    final formKey = GlobalKey<FormState>();
 
    final title = TextEditingController(text: existing?['title'] ?? '');
    final description = TextEditingController(
      text: existing?['description'] ?? '',
    );
    final sourceName = TextEditingController(
      text: existing?['sourceName'] ?? '',
    );
    final sourceUrl = TextEditingController(text: existing?['sourceUrl'] ?? '');
    final latitude = TextEditingController(
      text: existing?['latitude']?.toString() ?? '',
    );
    final longitude = TextEditingController(
      text: existing?['longitude']?.toString() ?? '',
    );
    final radius = TextEditingController(
      text: existing?['radiusKm']?.toString() ?? '5',
    );
 
    final countries = OfficerFirebaseService.southeastAsianCountries;
 
    String country = _pick(existing?['country'], countries, 'Malaysia');
    String type = _pick(existing?['type'], _types, 'Travel Advisory');
    String risk = _pick(existing?['risk'], _risks, 'Medium');
    String status = _pick(existing?['status'], _statuses, 'Active');
    bool emergency = existing?['isEmergency'] ?? false;
 
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(id == null ? 'Create Safety Alert' : 'Edit Safety Alert'),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: title,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Enter a title'
                          : null,
                    ),
                    TextFormField(
                      controller: description,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 4,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Enter a description'
                          : null,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: country,
                      decoration: const InputDecoration(labelText: 'Country'),
                      items: countries
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => country = v);
                      },
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: const InputDecoration(
                        labelText: 'Alert type',
                      ),
                      items: _types
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => type = v);
                      },
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: risk,
                      decoration: const InputDecoration(
                        labelText: 'Risk level',
                      ),
                      items: _risks
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => risk = v);
                      },
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: _statuses
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => status = v);
                      },
                    ),
                    TextFormField(
                      controller: sourceName,
                      decoration: const InputDecoration(
                        labelText: 'Source name',
                      ),
                    ),
                    TextFormField(
                      controller: sourceUrl,
                      decoration: const InputDecoration(
                        labelText: 'Source URL',
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Emergency alert'),
                      value: emergency,
                      onChanged: (v) => setDialogState(() => emergency = v),
                    ),
                    if (emergency) ...[
                      TextFormField(
                        controller: latitude,
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        validator: (v) {
                          if (!emergency) return null;
                          final n = double.tryParse(v ?? '');
                          if (n == null || n < -90 || n > 90) {
                            return 'Enter a latitude from -90 to 90';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: longitude,
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        validator: (v) {
                          if (!emergency) return null;
                          final n = double.tryParse(v ?? '');
                          if (n == null || n < -180 || n > 180) {
                            return 'Enter a longitude from -180 to 180';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: radius,
                        decoration: const InputDecoration(
                          labelText: 'Alert radius (km)',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) {
                          if (!emergency) return null;
                          final n = double.tryParse(v ?? '');
                          if (n == null || n <= 0) {
                            return 'Enter a radius greater than zero';
                          }
                          return null;
                        },
                      ),
                    ],
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
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
 
                final data = <String, dynamic>{
                  'title': title.text.trim(),
                  'description': description.text.trim(),
                  'country': country,
                  'type': type,
                  'risk': risk,
                  'status': status,
                  'sourceName': sourceName.text.trim(),
                  'sourceUrl': sourceUrl.text.trim(),
                  'isEmergency': emergency,
                };
 
                if (emergency) {
                  data['latitude'] = double.parse(latitude.text.trim());
                  data['longitude'] = double.parse(longitude.text.trim());
                  data['radiusKm'] = double.parse(radius.text.trim());
                }
 
                // Non-emergency alerts simply omit location fields.
                try {
                  if (id == null) {
                    await _service.addAlert(data);
                  } else {
                    await _service.updateAlert(id, data);
                  }
 
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('Could not save alert: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
 
    title.dispose();
    description.dispose();
    sourceName.dispose();
    sourceUrl.dispose();
    latitude.dispose();
    longitude.dispose();
    radius.dispose();
  }
 
  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete alert?'),
        content: const Text('This action cannot be undone.'),
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
        await _service.deleteAlert(id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Could not delete alert: $e')));
        }
      }
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.watchAlerts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load alerts.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
 
          final docs = snapshot.data!.docs;
 
          if (docs.isEmpty) {
            return const Center(child: Text('No safety alerts yet.'));
          }
 
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
 
              return Card(
                child: ListTile(
                  leading: Icon(
                    data['isEmergency'] == true
                        ? Icons.warning_amber
                        : Icons.notifications_active,
                    color: data['isEmergency'] == true
                        ? Colors.red
                        : Colors.orange,
                  ),
                  title: Text(data['title'] ?? 'Untitled alert'),
                  subtitle: Text(
                    '${data['country'] ?? ''} • '
                    '${data['risk'] ?? 'Unknown'} risk • '
                    '${data['status'] ?? 'Unknown'}\n'
                    '${data['description'] ?? ''}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showForm(id: doc.id, existing: data);
                      } else if (value == 'delete') {
                        _delete(doc.id);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add_alert),
        label: const Text('Create alert'),
      ),
    );
  }
}
