import 'package:flutter/material.dart';
import 'package:seafety_travel/shared/models/app_user.dart';
import 'package:seafety_travel/shared/models/destination_model.dart';
import 'package:seafety_travel/shared/theme/app_theme.dart';
import '../services/destination_service.dart';

class DestinationsScreen extends StatelessWidget {
  final AppUser currentUser;
  const DestinationsScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final service = DestinationService();
    return StreamBuilder<List<DestinationModel>>(
      stream: service.publishedDestinations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text('Could not load destinations.'),
          );
        }
        final destinations = snapshot.data ?? [];
        if (destinations.isEmpty) {
          return const Center(
            child: Text('No published destinations yet.'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: destinations.length,
          itemBuilder: (context, i) {
            final d = destinations[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (d.imageurl.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Image.network(
                        d.imageurl,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Container(
                          height: 150,
                          color: AppColors.paleBlue,
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('${d.region}, ${d.country}'),
                        const SizedBox(height: 8),
                        Text(
                          d.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: d.categories
                              .map((c) => Chip(label: Text(c)))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
