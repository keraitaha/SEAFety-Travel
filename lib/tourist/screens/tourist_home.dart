import 'package:flutter/material.dart';
import 'package:seafety_travel/shared/models/app_user.dart';
import 'package:seafety_travel/shared/widgets/auth_gate.dart';
import '../services/tourist_store.dart';
import '../services/firestore_tourist_store.dart';
import '../widgets/tourist_ui.dart';
import 'explore_screen.dart';
import 'trips_screen.dart';
import 'tourist_chat_screen.dart';

class TouristHome extends StatefulWidget {
  final AppUser currentUser;
  final TouristStore? store;
  final bool preview;
  const TouristHome({super.key, required this.currentUser, this.store, this.preview = false});

  @override
  State<TouristHome> createState() => _TouristHomeState();
}

class _TouristHomeState extends State<TouristHome> {
  late final TouristStore store;
  late final bool ownsStore;
  int tab = 0;

  @override
  void initState() {
    super.initState();
    ownsStore = widget.store == null;
    store =
        widget.store ?? FirestoreTouristStore(userId: widget.currentUser.userid, userName: widget.currentUser.fullName);
    store.start().catchError((Object error) {
      store.loadError = shortError(error);
      store.loading = false;
      store.changed();
    });
  }

  @override
  void dispose() {
    if (ownsStore) store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, child) {
        final pages = [ExploreScreen(store: store), TripsScreen(store: store), TouristInboxScreen(store: store)];
        return Scaffold(
          backgroundColor: TouristPalette.background,
          appBar: AppBar(
            title: Text(['Explore', 'My Trips', 'Messages'][tab]),
            actions: [
              if (widget.preview)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Center(
                    child: Text('DEMO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              if (!widget.preview) const LogoutButton(),
            ],
          ),
          body: Column(
            children: [
              if (store.loadError != null)
                MaterialBanner(
                  content: Text(store.loadError!),
                  actions: [
                    TextButton(
                      onPressed: () {
                        store.loadError = null;
                        store.changed();
                      },
                      child: const Text('Dismiss'),
                    ),
                  ],
                ),
              Expanded(child: store.loading ? const Center(child: CircularProgressIndicator()) : pages[tab]),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (index) => setState(() => tab = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: 'Explore',
              ),
              NavigationDestination(
                icon: Icon(Icons.luggage_outlined),
                selectedIcon: Icon(Icons.luggage),
                label: 'Trips',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: 'Messages',
              ),
            ],
          ),
        );
      },
    );
  }
}
