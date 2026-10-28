import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OfficerDestinations extends StatelessWidget {
  const OfficerDestinations({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('destinations')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading destinations: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final destinations = snapshot.data?.docs ?? [];

          if (destinations.isEmpty) {
            return const Center(
              child: Text('No destinations found. Add one to get started.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: destinations.length,
            itemBuilder: (context, index) {
              final document = destinations[index];
              final data = document.data();

              final name = data['name'] ?? 'Unnamed destination';
              final country = data['country'] ?? 'Unknown country';
              final risk = data['risk'] ?? 'Unknown';
              final published = data['published'] == true;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.place)),
                  title: Text(name.toString()),
                  subtitle: Text(
                    '$country\nRisk: $risk • '
                    '${published ? 'Published' : 'Draft'}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showDestinationForm(
                          context,
                          documentId: document.id,
                          existingData: data,
                        );
                      } else if (value == 'delete') {
                        _confirmDelete(context, document.id, name.toString());
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                  onTap: () {
                    _showDestinationDetails(context, data);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDestinationForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Destination'),
      ),
    );
  }

  // Add or edit a destination.
  static Future<void> _showDestinationForm(
    BuildContext context, {
    String? documentId,
    Map<String, dynamic>? existingData,
  }) async {
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(
      text: existingData?['name']?.toString() ?? '',
    );
    final countryController = TextEditingController(
      text: existingData?['country']?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: existingData?['description']?.toString() ?? '',
    );
    final safetyController = TextEditingController(
      text: existingData?['safetyInformation']?.toString() ?? '',
    );
    final visaController = TextEditingController(
      text: existingData?['visaInformation']?.toString() ?? '',
    );
    final sourceController = TextEditingController(
      text: existingData?['sourceUrl']?.toString() ?? '',
    );

    String risk = existingData?['risk']?.toString() ?? 'Medium';
    bool published = existingData?['published'] == true;
    bool saving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                documentId == null ? 'Add Destination' : 'Edit Destination',
              ),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _textField(
                          nameController,
                          'Destination name',
                          required: true,
                        ),
                        _textField(
                          countryController,
                          'Country',
                          required: true,
                        ),
                        _textField(
                          descriptionController,
                          'Description',
                          required: true,
                          maxLines: 3,
                        ),
                        _textField(
                          safetyController,
                          'Safety information',
                          maxLines: 3,
                        ),
                        _textField(
                          visaController,
                          'Visa information',
                          maxLines: 3,
                        ),
                        _textField(sourceController, 'Source URL (optional)'),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: risk,
                          decoration: const InputDecoration(
                            labelText: 'Risk level',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Low', child: Text('Low')),
                            DropdownMenuItem(
                              value: 'Medium',
                              child: Text('Medium'),
                            ),
                            DropdownMenuItem(
                              value: 'High',
                              child: Text('High'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => risk = value);
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Publish destination'),
                          subtitle: const Text(
                            'Allow travellers to see this destination.',
                          ),
                          value: published,
                          onChanged: (value) {
                            setDialogState(() => published = value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          setDialogState(() => saving = true);

                          try {
                            final data = <String, dynamic>{
                              'name': nameController.text.trim(),
                              'country': countryController.text.trim(),
                              'description': descriptionController.text.trim(),
                              'safetyInformation': safetyController.text.trim(),
                              'visaInformation': visaController.text.trim(),
                              'sourceUrl': sourceController.text.trim(),
                              'risk': risk,
                              'published': published,
                              'lastUpdated': FieldValue.serverTimestamp(),
                            };

                            final collection = FirebaseFirestore.instance
                                .collection('destinations');

                            if (documentId == null) {
                              await collection.add(data);
                            } else {
                              await collection.doc(documentId).update(data);
                            }

                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  documentId == null
                                      ? 'Destination added successfully.'
                                      : 'Destination updated successfully.',
                                ),
                              ),
                            );
                          } catch (error) {
                            setDialogState(() => saving = false);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Could not save destination: $error',
                                ),
                              ),
                            );
                          }
                        },
                  child: Text(saving ? 'Saving...' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    countryController.dispose();
    descriptionController.dispose();
    safetyController.dispose();
    visaController.dispose();
    sourceController.dispose();
  }

  static Widget _textField(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          alignLabelWithHint: maxLines > 1,
        ),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$label is required';
                }
                return null;
              }
            : null,
      ),
    );
  }

  // Show the full destination information.
  static void _showDestinationDetails(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['name']?.toString() ?? 'Destination'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detail('Country', data['country']),
              _detail('Risk', data['risk']),
              _detail('Description', data['description']),
              _detail('Safety information', data['safetyInformation']),
              _detail('Visa information', data['visaInformation']),
              _detail('Source URL', data['sourceUrl']),
              _detail(
                'Status',
                data['published'] == true ? 'Published' : 'Draft',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static Widget _detail(String label, dynamic value) {
    final text = value?.toString().trim() ?? '';

    if (text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(text),
        ],
      ),
    );
  }

  // Ask for confirmation before deleting.
  static Future<void> _confirmDelete(
    BuildContext context,
    String documentId,
    String name,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete destination?'),
        content: Text(
          'Are you sure you want to delete "$name"? '
          'This action cannot be undone.',
        ),
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

    if (confirm != true || !context.mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('destinations')
          .doc(documentId)
          .delete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Destination deleted.')));
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete destination: $error')),
      );
    }
  }
}
