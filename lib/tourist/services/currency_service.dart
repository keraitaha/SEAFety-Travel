import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  Future<double> convertFromMyr(double amount, String currency) async {
    if (currency == 'MYR') return amount;
    final uri = Uri.parse('https://api.frankfurter.dev/v2/rate/MYR/$currency');
    final result = await http.get(uri).timeout(const Duration(seconds: 8));
    if (result.statusCode != 200) throw StateError('Rate unavailable');
    final rate = (jsonDecode(result.body)['rate'] as num).toDouble();
    return amount * rate;
  }
}
