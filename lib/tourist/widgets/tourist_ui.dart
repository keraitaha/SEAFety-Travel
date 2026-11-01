import 'package:flutter/material.dart';
import 'package:seafety_travel/shared/theme/app_theme.dart';
import 'package:seafety_travel/shared/models/tourist_data.dart';

class TouristPalette {
  static const navy = Color(0xFF0B3D91);
  static const blue = Color(0xFF2878C8);
  static const aqua = Color(0xFF69D8EE);
  static const ice = Color(0xFFD9EFFA);
  static const background = Color(0xFFF7FAFD);
}

class SectionTitle extends StatelessWidget {
  final String text;
  final String? subtitle;
  const SectionTitle(this.text, {super.key, this.subtitle});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: TouristPalette.navy,
          ),
        ),
        if (subtitle != null)
          Text(subtitle!, style: TextStyle(color: Colors.blueGrey.shade600)),
      ],
    ),
  );
}

class InfoCard extends StatelessWidget {
  final Widget child;
  const InfoCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFDCE9F2)),
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0B143D6A),
          blurRadius: 14,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Material(type: MaterialType.transparency, child: child),
  );
}

class DestinationArt extends StatelessWidget {
  final String imageUrl;
  final double height;
  final IconData icon;
  const DestinationArt({
    super.key,
    required this.imageUrl,
    this.height = 140,
    this.icon = Icons.landscape_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: imageUrl.isEmpty
            ? Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      TouristPalette.navy,
                      TouristPalette.blue,
                      TouristPalette.aqua,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -18,
                      top: -25,
                      child: Icon(
                        Icons.circle_outlined,
                        color: Colors.white.withValues(alpha: 0.14),
                        size: 150,
                      ),
                    ),
                    Center(child: Icon(icon, color: Colors.white, size: 58)),
                  ],
                ),
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const ColoredBox(
                  color: TouristPalette.ice,
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: TouristPalette.navy,
                      size: 36,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class RiskChip extends StatelessWidget {
  final String risk;
  const RiskChip(this.risk, {super.key});

  @override
  Widget build(BuildContext context) {
    final lower = risk.toLowerCase();
    final color = lower == 'high'
        ? Colors.red.shade700
        : lower == 'medium'
        ? Colors.orange.shade800
        : lower == 'low'
        ? Colors.green.shade700
        : Colors.blueGrey;
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(
        '${risk.isEmpty ? 'Unknown' : risk} risk',
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
      backgroundColor: color.withValues(alpha: 0.09),
      side: BorderSide.none,
    );
  }
}

class LabelValue extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const LabelValue({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primaryBlue, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    ),
  );
}

void showNotice(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}

String shortError(Object error) {
  if (error is FormatException) return error.message;
  if (error is StateError) return error.message;
  return 'Action failed. Please check your connection or permissions.';
}

Widget wideAction(String label, VoidCallback? onPressed, {IconData? icon}) {
  return SizedBox(
    width: double.infinity,
    child: icon == null
        ? ElevatedButton(onPressed: onPressed, child: Text(label))
        : ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          ),
  );
}

String locationOf(Place place) => '${place.region}, ${place.country}';
