import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/officer_firebase_service.dart';

class OfficerUserManagement extends StatefulWidget {
  const OfficerUserManagement({super.key});

  @override
  State<OfficerUserManagement> createState() =>
      _OfficerUserManagementState();
}

class _OfficerUserManagementState
    extends State<OfficerUserManagement> {
  final OfficerFirebaseService _service =
      OfficerFirebaseService();

  String _searchQuery = '';

  Future<void> _changeUserRole({
    required String userId,
    required String userName,
    required int currentRole,
    required int newRole,
  }) async {
    if (currentRole == newRole) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Role Change'),
        content: Text(
          'Change $userName from '
          '${OfficerFirebaseService.getRoleName(currentRole)} '
          'to ${OfficerFirebaseService.getRoleName(newRole)}?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _service.updateUserRole(
        userId: userId,
        newRole: newRole,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$userName is now '
            '${OfficerFirebaseService.getRoleName(newRole)}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update role: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search by name or email',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.trim().toLowerCase();
              });
            },
          ),
        ),

        Expanded(
          child: StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
            stream: _service.watchUsers(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text('Unable to load users.'),
                );
              }

              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final users = snapshot.data?.docs ?? [];

              final filteredUsers = users.where((document) {
                final data = document.data();

                final firstName =
                    (data['firstname'] ?? '').toString();

                final lastName =
                    (data['lastname'] ?? '').toString();

                final email =
                    (data['email'] ?? '').toString();

                final fullName =
                    '$firstName $lastName'.toLowerCase();

                return fullName.contains(_searchQuery) ||
                    email.toLowerCase().contains(_searchQuery);
              }).toList();

              if (filteredUsers.isEmpty) {
                return const Center(
                  child: Text('No users found.'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final document = filteredUsers[index];
                  final data = document.data();

                  final firstName =
                      (data['firstname'] ?? '').toString();

                  final lastName =
                      (data['lastname'] ?? '').toString();

                  final email =
                      (data['email'] ?? 'No email').toString();

                  final country =
                      (data['country'] ?? 'Unknown').toString();

                  final rawRole = data['role'];

                  final currentRole = rawRole is num
                      ? rawRole.toInt()
                      : -1;

                  final userName =
                      '$firstName $lastName'.trim().isEmpty
                          ? email
                          : '$firstName $lastName'.trim();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                child: Icon(Icons.person),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      email,
                                      style: const TextStyle(
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const Divider(height: 24),

                          _infoRow('Country', country),

                          const SizedBox(height: 12),

                          _infoRow(
                            'Current Role',
                            OfficerFirebaseService.getRoleName(
                              currentRole,
                            ),
                          ),

                          const SizedBox(height: 16),

                          const Text(
                            'Change User Role',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 8),

                          DropdownButtonFormField<int>(
                            value: OfficerFirebaseService
                                    .validUserRoles
                                    .contains(currentRole)
                                ? currentRole
                                : null,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            hint: const Text('Select a role'),
                            items: const [
                              DropdownMenuItem(
                                value: 0,
                                child: Text('Tourist'),
                              ),
                              DropdownMenuItem(
                                value: 1,
                                child: Text('Travel Agency'),
                              ),
                              DropdownMenuItem(
                                value: 2,
                                child: Text('Tourism Officer'),
                              ),
                            ],
                            onChanged: currentRole == -1
                                ? null
                                : (newRole) {
                                    if (newRole == null) return;

                                    _changeUserRole(
                                      userId: document.id,
                                      userName: userName,
                                      currentRole: currentRole,
                                      newRole: newRole,
                                    );
                                  },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
