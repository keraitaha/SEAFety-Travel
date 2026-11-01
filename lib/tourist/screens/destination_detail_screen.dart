import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seafety_travel/shared/models/tourist_data.dart';
import '../services/tourist_store.dart';
import '../widgets/tourist_ui.dart';
import 'package_detail_screen.dart';
import 'tourist_chat_screen.dart';

class DestinationDetailScreen extends StatelessWidget {
  final TouristStore store;
  final Place place;
  const DestinationDetailScreen({
    super.key,
    required this.store,
    required this.place,
  });

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) {
      final current = store.placeById(place.id);
      if (current == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Destination')),
          body: const Center(child: Text('Destination no longer available.')),
        );
      }
      return _details(context, current);
    },
  );

  Widget _details(BuildContext context, Place place) {
    final warnings = store.alertsFor(place);
    final packages = store.packages
        .where((p) => p.destinationId == place.id)
        .toList();
    return Scaffold(
      backgroundColor: TouristPalette.background,
      appBar: AppBar(title: Text(place.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DestinationArt(
            imageUrl: place.imageUrl,
            height: 190,
            icon: Icons.travel_explore,
          ),
          const SizedBox(height: 14),
          Text(
            place.name,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: TouristPalette.navy,
            ),
          ),
          Text(
            locationOf(place),
            style: TextStyle(color: Colors.blueGrey.shade600),
          ),
          const SizedBox(height: 8),
          Text(place.description),
          const SectionTitle(
            'Destination safety',
            subtitle: 'Officer-maintained, source-attributed information',
          ),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RiskChip(place.safetyLevel),
                LabelValue(
                  icon: Icons.schedule,
                  label: 'Opening hours',
                  value: place.openingHours,
                ),
                LabelValue(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Entrance fee',
                  value: place.entranceFee == null
                      ? 'Not provided'
                      : money(place.entranceFee!),
                ),
                if (place.safetyInfo.isNotEmpty)
                  LabelValue(
                    icon: Icons.info_outline,
                    label: 'Safety guidance',
                    value: place.safetyInfo,
                  ),
                LabelValue(
                  icon: Icons.fact_check_outlined,
                  label: 'Visa guidance',
                  value: place.visaInfo,
                ),
                LabelValue(
                  icon: Icons.health_and_safety_outlined,
                  label: 'Emergency information',
                  value: place.emergencyInfo,
                ),
                if (place.sourceUrl.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _copy(context, place.sourceUrl),
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy official source URL'),
                  ),
              ],
            ),
          ),
          const SectionTitle('Current advisories'),
          if (warnings.isEmpty)
            const InfoCard(
              child: Text(
                'No published advisories for this destination. This does not guarantee safety.',
              ),
            ),
          ...warnings.map(
            (warning) => InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          warning.title,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      RiskChip(warning.riskLevel),
                    ],
                  ),
                  Text(
                    '${warning.riskType.replaceAll('_', ' ')} · ${warning.description}',
                  ),
                  if (warning.updatedAt != null)
                    Text(
                      'Updated: ${warning.updatedAt!.toLocal().toString().substring(0, 16)}',
                      style: TextStyle(
                        color: Colors.blueGrey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  if (warning.sourceUrl.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _copy(context, warning.sourceUrl),
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy alert source'),
                    ),
                ],
              ),
            ),
          ),
          const SectionTitle('Available packages'),
          if (packages.isEmpty)
            const InfoCard(child: Text('No packages published yet.')),
          ...packages.map(
            (item) => InfoCard(
              child: ListTile(
                title: Text(item.title),
                subtitle: Text('${item.durationDays} days'),
                trailing: Text(
                  money(item.price),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: TouristPalette.navy,
                  ),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PackageDetailScreen(store: store, item: item),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          wideAction(
            'Ask a tourism officer',
            store.officerId == null
                ? null
                : () async {
                    try {
                      final thread = await store.openConversation(
                        staffId: store.officerId!,
                        type: 'officer',
                      );
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TouristChatScreen(store: store, thread: thread),
                        ),
                      );
                    } catch (error) {
                      showNotice(context, shortError(error));
                    }
                  },
            icon: Icons.support_agent,
          ),
          const SizedBox(height: 12),
          Text(
            'SEAfety Travel is not an emergency service. For immediate danger, contact local authorities.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600),
          ),
        ],
      ),
    );
  }

  void _copy(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));
    showNotice(context, 'Source URL copied.');
  }
}
