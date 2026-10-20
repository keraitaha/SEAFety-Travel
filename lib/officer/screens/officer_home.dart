import 'package:flutter/material.dart';
import '../../shared/models/app_user.dart';
import '../../shared/widgets/auth_gate.dart';

// Placeholder for the Tourism Officer module (owned by a teammate).
class OfficerHome extends StatelessWidget {
  final AppUser currentUser;
  const OfficerHome({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tourism Officer'),
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
              const Text('Tourism Officer module coming soon.'),
            ],
          ),
        ),
      ),
    );
  }
}
