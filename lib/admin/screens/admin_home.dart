import 'package:flutter/material.dart';
import '../../shared/models/app_user.dart';
import '../../shared/widgets/auth_gate.dart';

// Placeholder for the Administrator module (owned by a teammate).
class AdminHome extends StatelessWidget {
  final AppUser currentUser;
  const AdminHome({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrator'),
        actions: const [LogoutButton()],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Welcome, ${currentUser.firstname}'),
              const SizedBox(height: 8),
              const Text('Administrator module coming soon.'),
            ],
          ),
        ),
      ),
    );
  }
}
