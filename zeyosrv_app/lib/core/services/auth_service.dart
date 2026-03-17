import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';
import 'location_service.dart';

class AuthService {
  
  // Send OTP
  static Future<void> sendOtp(String phone) async {
    await ApiService.post(ApiConstants.authLogin, {'phone': phone});
  }

  // Verify OTP and Save Token
  static Future<Map<String, dynamic>> verifyOtp(String phone, String code) async {
    final response = await ApiService.post(ApiConstants.authVerify, {
      'phone': phone,
      'code': code,
      'role': 'technician' // Important
    });
    
    // Save Token
    if (response['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', response['token']);
      await prefs.setString('tech_id', response['user']['id']);
      await prefs.setString('user_phone', response['user']['phone']);
      await prefs.setString('user_role', response['user']['role'] ?? 'technician');
    }

    return response;
  }
  
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('tech_id');
    await prefs.remove('user_phone');
    await prefs.remove('user_role');
    
    // Disconnect Socket to update DB status to Offline
    LocationService.stopTracking();
  }
}
