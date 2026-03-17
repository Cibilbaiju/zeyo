import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

class AuthServiceBackend {
  
  // Send OTP
  static Future<void> sendOtp(String phone) async {
    await ApiService.post(ApiConstants.authLogin, {'phone': phone});
  }

  // Verify OTP and Save Token
  static Future<Map<String, dynamic>> verifyOtp(String phone, String code) async {
    final response = await ApiService.post(ApiConstants.authVerify, {
      'phone': phone,
      'code': code,
      'role': 'user' // Important: Zeyo App is for users
    });
    
    // Save Token
    if (response['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', response['token']);
      await prefs.setString('user_id', response['user']['id']);
      await prefs.setString('user_role', response['user']['role']);
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
    await prefs.remove('user_id');
    await prefs.remove('user_role');
  }
}
