import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class ImgBBService {
  final String _apiKey;

  ImgBBService({String? apiKey})
      : _apiKey = apiKey ?? ApiConstants.imgbbApiKey;

  Future<String?> uploadImage(String base64Image) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.imgbbBaseUrl}${ApiConstants.imgbbUploadEndpoint}',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['key'] = _apiKey
        ..fields['image'] = base64Image;

      final streamedResponse = await request.send().timeout(
        ApiConstants.imgbbTimeout,
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return data['data']['url'] as String;
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}
