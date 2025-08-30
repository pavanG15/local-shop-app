import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:local_shop_app/config/cloudinary_config.dart';

class CloudinaryService {
  // Unsigned upload to Cloudinary
  Future<Map<String, String>?> uploadImage(XFile imageFile) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload');

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset;

    // Read the image bytes for web compatibility
    final bytes = await imageFile.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: imageFile.name,
    ));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final result = json.decode(utf8.decode(responseData));
        return {
          'secure_url': result['secure_url'],
          'public_id': result['public_id'],
        };
      } else {
        final responseData = await response.stream.bytesToString();
        print('Cloudinary upload failed with status ${response.statusCode}: $responseData');
        return null;
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  // Call webhook to delete image from Cloudinary
  Future<bool> deleteImage(String publicId) async {
    if (CloudinaryConfig.deleteWebhookUrl == "YOUR_VERCEL_NETLIFY_WEBHOOK_URL" || CloudinaryConfig.deleteWebhookUrl.isEmpty) {
      print("Cloudinary delete webhook URL is not configured.");
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse(CloudinaryConfig.deleteWebhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'public_id': publicId}),
      );

      if (response.statusCode == 200) {
        print('Image deletion webhook called successfully for public_id: $publicId');
        return true;
      } else {
        print('Image deletion webhook failed with status ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error calling image deletion webhook: $e');
      return false;
    }
  }
}
