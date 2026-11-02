import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../auth/login_screen.dart';
import 'package:seafety_travel/agency/screens/agency_home.dart';
import 'package:seafety_travel/tourist/screens/tourist_home.dart';
import 'package:seafety_travel/officer/screens/officer_home.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return StreamBuilder<User?>(
      stream: authService.authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const _LoadingScreen();

        final user = snapshot.data;
        if (user == null) return const LoginScreen();

        return _RoleRouter(userid: user.uid);
      },
    );
  }
}

class _RoleRouter extends StatelessWidget {
  final String userid;
  const _RoleRouter({required this.userid});

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    return FutureBuilder<AppUser?>(
      future: userService.getUser(userid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const _LoadingScreen();

        final appUser = snapshot.data;
        if (appUser == null) return const _ErrorScreen(message: 'Could not load your profile. Please log in again.');

        switch (appUser.role) {
          case 1:
            return AgencyHome(currentUser: appUser);
          case 2:
            return OfficerHome(currentUser: appUser);
          default:
            return TouristHome(currentUser: appUser);
        }
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;
  const _ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => AuthService().signOut(), child: const Text('Back to Login')),
            ],
          ),
        ),
      ),
    );
  }
}

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Log out',
      onPressed: () async {
        await AuthService().signOut();
      },
    );
  }
}
