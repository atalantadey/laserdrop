import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'http://192.168.1.3:5000'; // Update with your actual IP

  static Future<Map<String, dynamic>> analyzeImage(String imagePath) async {
    const int maxRetries = 3;
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        var request =
            http.MultipartRequest('POST', Uri.parse('$baseUrl/analyze'));
        request.files
            .add(await http.MultipartFile.fromPath('image', imagePath));

        // Add a timeout of 30 seconds (increased from 10)
        var response = await request.send().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Server is unresponsive. Please try again later.');
          },
        );

        var responseData = await http.Response.fromStream(response).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Server is unresponsive while receiving data.');
          },
        );

        if (response.statusCode == 200) {
          return jsonDecode(responseData.body);
        } else {
          throw Exception(
              'Server error: ${response.statusCode} - ${responseData.body}');
        }
      } catch (e) {
        attempt++;
        if (attempt == maxRetries) {
          rethrow; // Throw the error if all retries fail
        }
        // Wait before retrying (exponential backoff: 1s, 2s, 4s)
        await Future.delayed(Duration(seconds: 1 << attempt));
      }
    }
    throw Exception('Failed to analyze image after $maxRetries attempts.');
  }
}
