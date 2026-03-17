import 'package:flutter/material.dart';
import '../services/auth_service_backend.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

class User {
  final String id;
  final String phone;
  final String? email;
  final Map<String, dynamic>? userMetadata;

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
    final token = await AuthServiceBackend.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        ApiService.setToken(token); // Enable auth for future requests
        final userData = await ApiService.get(ApiConstants.usersMe);
        
        _user = User(
          id: userData['id'],
          phone: userData['phone'],
          email: userData['email'],
          userMetadata: userData
        );
      } catch (e) {
        // Token invalid or network error
        print("UserProvider: Failed to fetch profile: $e");
        await AuthServiceBackend.logout();
        _user = null;
      }
    } else {
      _user = null;
    }
    _isLoading = false;
    notifyListeners();
  }
  
  void loginSuccess() {
    // Reload profile
    _init(); 
  }

  Future<void> signOut() async {
    await AuthServiceBackend.logout();
    _user = null;
    notifyListeners();
  }
}
