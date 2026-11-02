import 'dart:convert';
import 'package:http/http.dart' as http;

class CountryService {
  // Country list API
  static const String _url = 'https://countriesnow.space/api/v0.1/countries/positions';

  // Incase API fails
  static const List<String> _fallback = [
    'Australia',
    'China',
    'India',
    'Indonesia',
    'Japan',
    'Malaysia',
    'Philippines',
    'Singapore',
    'South Korea',
    'Thailand',
    'United Kingdom',
    'United States',
    'Vietnam',
  ];

  Future<List<String>> getCountries() async {
    try {
      final response = await http.get(Uri.parse(_url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> data = body['data'] ?? [];
        final names = <String>[];
        for (final item in data) {
          final name = item['name'];
          if (name is String && name.isNotEmpty) {
            names.add(name);
          }
        }
        names.sort();
        if (names.isNotEmpty) return names;
      }
      return _fallback;
    } catch (e) {
      return _fallback;
    }
  }
}
