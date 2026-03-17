import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class User {
  final String id;
  final String phone;
  final String? email;
  final Map<String, dynamic>? userMetadata; // Added for compatibility

  User({required this.id, required this.phone, this.email, this.userMetadata});
}

class UserProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = true;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;

  UserProvider() {
    _init();
  }

  Future<void> _init() async {
    final token = await AuthService.getToken();
    if (token != null && token.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('user_phone');
      final id = prefs.getString('tech_id') ?? 'unknown-id';
      
      _user = User(
        id: id,
        phone: phone ?? '+91-XXXXXXXXXX',
      ); 
    } else {
      _user = null;
    }
    _isLoading = false;
    notifyListeners();
  }
  
  void loginSuccess(Map<String, dynamic> userMap) {
    _user = User(
      id: userMap['id'], 
      phone: userMap['phone'],
      email: userMap['email'],
      userMetadata: userMap,
    );
    notifyListeners();
  }

  Future<void> signOut() async {
    await AuthService.logout();
    _user = null;
    notifyListeners();
  }
}
