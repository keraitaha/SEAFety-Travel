import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/officer_firebase_service.dart';

class OfficerEmergencyResources extends StatefulWidget {
  const OfficerEmergencyResources({super.key});

  @override
  State<OfficerEmergencyResources> createState() =>
      _OfficerEmergencyResourcesState();
}

class _OfficerEmergencyResourcesState
    extends State<OfficerEmergencyResources> {
  final _service = OfficerFirebaseService();

  Future<void> _showForm() async {
    final formKey = GlobalKey<FormState>();

    final title = TextEditingController();
    final hostCountry = TextEditingController();
    final phone = TextEditingController();
    final address = TextEditingController();
    final instructions = TextEditingController();
    final sourceUrl = TextEditingController();

    String country = 'Malaysia';
    String resourceType = 'Embassy';

    final countries = OfficerFirebaseService.southeastAsianCountries;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Emergency Resource'),
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
                      decoration: const InputDecoration(
                        labelText: 'Resource name',
                        hintText: 'e.g. Embassy of Malaysia',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Enter a resource name'
                          : null,
                    ),
                    DropdownButtonFormField<String>(
                      value: resourceType,
                      decoration: const InputDecoration(
                        labelText: 'Resource type',
                      ),
                      items: [
                        'Embassy',
                        'Local Authority',
                        'Emergency Instructions',
                      ]
                          .map((v) => DropdownMenuItem(
                                value: v,
                                child: Text(v),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => resourceType = v);
                        }
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: country,
                      decoration: const InputDecoration(
                        labelText: 'Country covered',
                      ),
                      items: countries
                          .map((v) => DropdownMenuItem(
                                value: v,
                                child: Text(v),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => country = v);
                        }
                      },
                    ),
                    TextFormField(
                      controller: hostCountry,
                      decoration: const InputDecoration(
                        labelText: 'Host country (optional)',
                        hintText: 'e.g. Thailand',
                      ),
                    ),
                    TextFormField(
                      controller: phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone number (optional)',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    TextFormField(
                      controller: address,
                      decoration: const InputDecoration(
                        labelText: 'Address (optional)',
                      ),
                      maxLines: 2,
                    ),
                    TextFormField(
                      controller: instructions,
                      decoration: const InputDecoration(
                        labelText: 'Emergency instructions',
                      ),
                      maxLines: 4,
                    ),
                    TextFormField(
                      controller: sourceUrl,
                      decoration: const InputDecoration(
                        labelText: 'Official source URL',
                      ),
                      keyboardType: TextInputType.url,
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
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final data = <String, dynamic>{
                  'title': title.text.trim(),
                  'resourceType': resourceType,
                  'country': country,
                  'hostCountry': hostCountry.text.trim(),
                  'phone': phone.text.trim(),
                  'address': address.text.trim(),
                  'instructions': instructions.text.trim(),
                  'sourceUrl': sourceUrl.text.trim(),
                };

                try {
                  await _service.addResource(data);

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text('Could not save resource: $e'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Save Resource'),
            ),
          ],
        ),
      ),
    );

    title.dispose();
    hostCountry.dispose();
    phone.dispose();
    address.dispose();
    instructions.dispose();
    sourceUrl.dispose();
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete resource?'),
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
        await _service.deleteResource(id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not delete resource: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.watchResources(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Could not load emergency resources.'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text('No emergency resources have been added.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              IconData icon;

              switch (data['resourceType']) {
                case 'Embassy':
                  icon = Icons.account_balance;
                  break;
                case 'Local Authority':
                  icon = Icons.local_police;
                  break;
                default:
                  icon = Icons.menu_book;
              }

              return Card(
                child: ExpansionTile(
                  leading: Icon(icon, color: Colors.blue),
                  title: Text(data['title'] ?? 'Untitled resource'),
                  subtitle: Text(
                    '${data['resourceType'] ?? 'Other'} • '
                    '${data['country'] ?? ''}',
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(
                    16, 0, 16, 16,
                  ),
                  children: [
                    if ((data['hostCountry'] ?? '').toString().isNotEmpty)
                      _detail('Host country', data['hostCountry']),
                    if ((data['phone'] ?? '').toString().isNotEmpty)
                      _detail('Phone', data['phone']),
                    if ((data['address'] ?? '').toString().isNotEmpty)
                      _detail('Address', data['address']),
                    if ((data['instructions'] ?? '').toString().isNotEmpty)
                      _detail('Instructions', data['instructions']),
                    if ((data['sourceUrl'] ?? '').toString().isNotEmpty)
                      _detail('Official source', data['sourceUrl']),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _delete(doc.id),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete resource'),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showForm,
        icon: const Icon(Icons.add),
        label: const Text('Add resource'),
      ),
    );
  }

  Widget _detail(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: Text('$label: $value'),
      ),
    );
  }
}