import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class AddressService {
  
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<List<dynamic>> getAddresses() async {
    final token = await _getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/addresses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load addresses');
      }
    } catch (e) {
      print('Error fetching addresses: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> addAddress(Map<String, dynamic> addressData) async {
    final token = await _getToken();
    if (token == null) return null;

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/addresses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(addressData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to add address. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to add address: ${response.body}');
      }
    } catch (e) {
      print('Error adding address: $e');
      return null;
    }
  }

  static Future<bool> updateAddress(String id, Map<String, dynamic> addressData) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/addresses/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(addressData),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating address: $e');
      return false;
    }
  }

  static Future<bool> deleteAddress(String id) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/addresses/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting address: $e');
      return false;
    }
  }
}
