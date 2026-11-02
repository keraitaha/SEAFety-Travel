import 'package:flutter/material.dart';
import 'package:seafety_travel/shared/models/app_user.dart';
import 'package:seafety_travel/shared/widgets/auth_gate.dart';
import 'officer_dashboard.dart';
import 'officer_destinations.dart';
import 'officer_alert.dart';
import 'officer_safety_map.dart';
import 'officer_emergency_resources.dart';
import 'officer_enquiries.dart';
import 'officer_user_management.dart';

class OfficerHome extends StatefulWidget {
  final AppUser currentUser;

  const OfficerHome({super.key, required this.currentUser});

  @override
  State<OfficerHome> createState() => _OfficerHomeState();
}

class _OfficerHomeState extends State<OfficerHome> {
  int _selectedIndex = 0;

  late final List<Widget> _screens = [
    OfficerDashboard(currentUser: widget.currentUser),
    const OfficerDestinations(),
    const OfficerAlerts(),
    const OfficerSafetyMap(),
    const OfficerEmergencyResources(),
    const OfficerUserManagement(),
  ];

  final List<String> _titles = [
    'Officer Dashboard',
    'Destinations',
    'Safety Alerts',
    'Safety Map',
    'Emergency Resources',
    'User Management',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            tooltip: 'Tourist enquiries',
            icon: const Icon(Icons.chat_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    OfficerEnquiries(currentUser: widget.currentUser),
              ),
            ),
          ),
          const LogoutButton(),
        ],
      ),

      body: IndexedStack(index: _selectedIndex, children: _screens),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.place_outlined),
            selectedIcon: Icon(Icons.place),
            label: 'Places',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Safety Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.emergency_outlined),
            selectedIcon: Icon(Icons.emergency),
            label: 'Emergency',
          ),
          NavigationDestination(
            icon: Icon(Icons.manage_accounts_outlined),
            selectedIcon: Icon(Icons.manage_accounts),
            label: 'Users',
          ),
        ],
      ),
    );
  }
}
