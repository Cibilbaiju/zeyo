import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static Future<Map<String, String>> _getHeaders() async {
    // Lazy import or pass token
    // For simplicity, reading from SharedPreferences directly here requires importing it
    // But better to pass it. However, to keep it simple and static:
    return {'Content-Type': 'application/json'};
  }

  // Allow injecting token for authorized requests
  static String? _authToken;
  static void setToken(String token) => _authToken = token;

  static Future<dynamic> get(String url) async {
    try {
      final headers = {'Content-Type': 'application/json'};
      if (_authToken != null) headers['Authorization'] = 'Bearer $_authToken';

      final response = await http.get(Uri.parse(url), headers: headers);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }

  static Future<dynamic> post(String url, Map<String, dynamic> body) async {
    try {
      final headers = {'Content-Type': 'application/json'};
      if (_authToken != null) headers['Authorization'] = 'Bearer $_authToken';

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.trim().isEmpty) return {};
      return jsonDecode(response.body);
    } else {
      print('API Error: ${response.statusCode} - ${response.body}');
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Server Error: ${response.statusCode}');
      } catch (e) {
         if (e.toString().contains('exception')) rethrow;
         throw Exception('Server Error: ${response.statusCode} - ${response.body}');
      }
    }
  }
}
