import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // Use localhost for Chrome/iOS Simulator, or 10.0.2.2 for Android Emulator
  static String get baseUrl {
    return dotenv.env['API_BASE_URL'] ?? 'http://localhost:5005/api';
  }

  static String get socketUrl {
     return baseUrl.replaceAll('/api', '');
  }
  
  // Auth Routes
  static String get authLogin => '$baseUrl/auth/login';
  static String get authVerify => '$baseUrl/auth/verify';
  
  // Job Routes
  // Job Routes
  static String get jobsRequest => '$baseUrl/jobs/request';
  
  // User Routes
  static String get usersMe => '$baseUrl/users/me';
}
