import 'package:flutter/material.dart';
import 'package:seafety_travel/shared/models/app_user.dart';
import 'package:seafety_travel/shared/widgets/auth_gate.dart';
import 'packages_screen.dart';
import 'destinations_screen.dart';
import 'bookings_screen.dart';
import 'enquiries_screen.dart';

class AgencyHome extends StatefulWidget {
  final AppUser currentUser;
  const AgencyHome({super.key, required this.currentUser});

  @override
  State<AgencyHome> createState() => _AgencyHomeState();
}

class _AgencyHomeState extends State<AgencyHome> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      PackagesScreen(currentUser: widget.currentUser),
      DestinationsScreen(currentUser: widget.currentUser),
      BookingsScreen(currentUser: widget.currentUser),
      EnquiriesScreen(currentUser: widget.currentUser),
    ];
    final titles = ['My Packages', 'Destinations', 'Bookings', 'Enquiries'];

    return Scaffold(
      appBar: AppBar(title: Text(titles[_index]), actions: [const LogoutButton()]),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.card_travel), label: 'Packages'),
          NavigationDestination(icon: Icon(Icons.place), label: 'Destinations'),
          NavigationDestination(icon: Icon(Icons.book_online), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.chat), label: 'Enquiries'),
        ],
      ),
    );
  }
}
