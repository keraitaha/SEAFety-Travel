import 'package:flutter/material.dart';
import 'package:seafety_travel/shared/models/tourist_data.dart';
import '../services/tourist_store.dart';
import '../widgets/tourist_ui.dart';
import 'destination_detail_screen.dart';
import 'package_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  final TouristStore store;
  const ExploreScreen({super.key, required this.store});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String query = '';
  String category = 'All';
  final Set<String> compared = {};

  @override
  Widget build(BuildContext context) {
    final places = widget.store.destinations.where((place) {
      final text = query.trim().toLowerCase();
      final matchesQuery = '${place.name} ${place.country} ${place.region}'.toLowerCase().contains(text);
      final matchesCategory =
          category == 'All' || place.categories.any((item) => item.toLowerCase() == category.toLowerCase());
      return matchesQuery && matchesCategory;
    }).toList();
    final packages = widget.store.packages
        .where((item) => widget.store.placeById(item.destinationId) != null && item.availability != 'unavailable')
        .toList();
    final width = MediaQuery.sizeOf(context).width;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(colors: [TouristPalette.navy, TouristPalette.blue, TouristPalette.aqua]),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset('assets/images/seafety_travel_logo.png', width: 38, height: 38),
                    const SizedBox(width: 10),
                    const Text(
                      'SEAfety Travel',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Go somewhere good.\nTravel informed.',
                  style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800, height: 1.12),
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (text) => setState(() => query = text),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search destinations',
                    fillColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SectionTitle('Explore by interest', subtitle: 'Discover destinations that match your plans'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', 'Beach', 'Culture', 'Food', 'Nature']
                .map(
                  (tag) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(tag),
                      selected: category == tag,
                      onSelected: (_) => setState(() => category = tag),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        SectionTitle('Recommended destinations', subtitle: '${places.length} places to explore'),
        if (places.isEmpty) const InfoCard(child: Text('No matching destinations. Try a different search.')),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 650 ? 2 : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: places.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 265,
              ),
              itemBuilder: (context, index) {
                final place = places[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _openPlace(place),
                  child: InfoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DestinationArt(imageUrl: place.imageUrl, height: 125),
                        const SizedBox(height: 10),
                        Text(
                          place.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          locationOf(place),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.blueGrey.shade600),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.shield_outlined, size: 16, color: TouristPalette.blue),
                            const SizedBox(width: 4),
                            Text(
                              '${place.safetyLevel.toUpperCase()} risk',
                              style: const TextStyle(fontSize: 12, color: TouristPalette.navy),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_forward, color: TouristPalette.navy),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SectionTitle('Travel packages', subtitle: 'Clear prices, inclusions and durations'),
        if (packages.isEmpty) const InfoCard(child: Text('No published packages available yet.')),
        ...packages.expand((item) {
          final destination = widget.store.placeById(item.destinationId);
          // Skip packages whose destination is missing or unpublished.
          if (destination == null) return <Widget>[];
          return [
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(color: TouristPalette.ice, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.card_travel_outlined, color: TouristPalette.navy),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                            Text(
                              '${destination.name} · ${item.durationDays} day(s)',
                              style: TextStyle(color: Colors.blueGrey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        money(item.price),
                        style: const TextStyle(color: TouristPalette.navy, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: compared.contains(item.id),
                        onChanged: (_) {
                          setState(() {
                            if (compared.contains(item.id)) {
                              compared.remove(item.id);
                            } else if (compared.length < 3) {
                              compared.add(item.id);
                            } else {
                              showNotice(context, 'Compare up to three packages.');
                            }
                          });
                        },
                      ),
                      const Text('Compare'),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _openPackage(item),
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: const Text('Details'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ];
        }),
        if (compared.length >= 2)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: wideAction('Compare ${compared.length} packages', _compare, icon: Icons.compare_arrows),
          ),
        if (width < 360) const SizedBox(height: 8),
      ],
    );
  }

  void _openPlace(Place place) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DestinationDetailScreen(store: widget.store, place: place),
    ),
  );

  void _openPackage(TravelPackage item) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PackageDetailScreen(store: widget.store, item: item),
    ),
  );

  void _compare() {
    final selected = widget.store.packages.where((item) => compared.contains(item.id)).toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: ListView(
            shrinkWrap: true,
            children: [
              const SectionTitle('Package comparison'),
              for (final item in selected)
                InfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${money(item.price)} · ${item.durationDays} day(s)'),
                      Text('Includes: ${item.inclusions.join(', ')}'),
                      Text('Availability: ${item.availability}'),
                    ],
                  ),
                ),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ],
          ),
        ),
      ),
    );
  }
}
