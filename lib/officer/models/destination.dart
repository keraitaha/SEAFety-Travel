class Destination {
  final String id;
  final String name;
  final String country;
  final String description;
  final String safetyInformation;
  final String visaInformation;
  final String sourceUrl;
  final String risk;
  final bool published;

  const Destination({
    required this.id,
    required this.name,
    required this.country,
    this.description = '',
    this.safetyInformation = '',
    this.visaInformation = '',
    this.sourceUrl = '',
    this.risk = 'Low',
    this.published = false,
  });

  factory Destination.fromMap(String id, Map<String, dynamic> data) {
    return Destination(
      id: id,
      name: data['name'] as String? ?? '',
      country: data['country'] as String? ?? '',
      description: data['description'] as String? ?? '',
      safetyInformation: data['safetyInformation'] as String? ?? '',
      visaInformation: data['visaInformation'] as String? ?? '',
      sourceUrl: data['sourceUrl'] as String? ?? '',
      risk: data['risk'] as String? ?? 'Low',
      published: data['published'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'country': country,
      'description': description,
      'safetyInformation': safetyInformation,
      'visaInformation': visaInformation,
      'sourceUrl': sourceUrl,
      'risk': risk,
      'published': published,
    };
  }
}
