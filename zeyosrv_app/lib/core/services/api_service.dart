import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static Future<dynamic> post(String url, Map<String, dynamic> body) async {
    try {
      final token = await _getToken();
      final headers = {'Content-Type': 'application/json'};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

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

  static Future<dynamic> get(String url) async {
    try {
      final token = await _getToken();
      final headers = {'Content-Type': 'application/json'};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }

  static dynamic _handleResponse(http.Response response) {
    print('DEBUG: ${response.request?.url} - Status: ${response.statusCode}');
    print('DEBUG: Body: "${response.body}"');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.trim().isEmpty) return {};
      try {
        return jsonDecode(response.body);
      } catch (e) {
        print('JSON Decode Error (Success Block): $e');
        print('Offending Body: ${response.body}');
        throw FormatException('Invalid JSON from server: "${response.body}"');
      }
    } else {
      print('API Error: ${response.statusCode} - ${response.body}');
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Something went wrong');
      } catch (e) {
         if (e is Exception && e.toString().contains('Something went wrong')) rethrow;
         throw Exception('Server Error: ${response.statusCode} ${response.body}');
      }
    }
  }
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}
