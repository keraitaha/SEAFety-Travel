import 'dart:convert';
import 'package:http/http.dart' as http;

class CountryService {
  // Free, no-key API. We only ask for the country name field.
  static const String _url = 'https://restcountries.com/v3.1/all?fields=name';

  // Used if the network call fails so signup still works offline.
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
        final List<dynamic> data = jsonDecode(response.body);
        final names = <String>[];
        for (final item in data) {
          final common = item['name']?['common'];
          if (common is String && common.isNotEmpty) {
            names.add(common);
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
