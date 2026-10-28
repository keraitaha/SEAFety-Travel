import 'package:flutter/material.dart';

import 'shared/models/app_user.dart';
import 'shared/widgets/logout_button.dart';

import 'screens/screens/screens/officer_dashboard.dart';
import 'screens/screens/screens/officer_destinations.dart';
import 'screens/screens/screens/officer_alerts.dart';
import 'screens/screens/screens/officer_safety_map.dart';
import 'screens/screens/screens/officer_emergency_resources.dart';

class OfficerHome extends StatefulWidget {
  final AppUser currentUser;

  const OfficerHome({
    super.key,
    required this.currentUser,
  });

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
  ];

  final List<String> _titles = [
    'Officer Dashboard',
    'Destinations',
    'Safety Alerts',
    'Safety Map',
    'Emergency Resources',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: const [
          LogoutButton(),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
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
        ],
      ),
    );
  }
}
