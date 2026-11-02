import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = 'p6kdvmgo';
  static const String uploadPreset = 'seafety_travel';

  // Uploads an image file to Cloudinary and returns the public secure URL
  static Future<String?> uploadImage(File imageFile) async {
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    try {
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonMap = jsonDecode(responseData);

        // Return the secure HTTPS image URL from Cloudinary
        return jsonMap['secure_url'] as String?;
      } else {
        return null;
      }
    } catch (_) {
      return null;
    }
  }
}
