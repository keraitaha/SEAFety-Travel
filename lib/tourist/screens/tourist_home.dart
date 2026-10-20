import 'package:flutter/material.dart';
import '../../shared/models/app_user.dart';
import '../../shared/widgets/auth_gate.dart';

// Placeholder for the Tourist module (owned by a teammate).
class TouristHome extends StatelessWidget {
  final AppUser currentUser;
  const TouristHome({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tourist'),
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
              const Text('Tourist module coming soon.'),
            ],
          ),
        ),
      ),
    );
  }
}
