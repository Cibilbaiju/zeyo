import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // AWS EC2 IP
  static String get baseUrl {
    return dotenv.env['API_BASE_URL'] ?? 'http://localhost:5005/api';
  }
  
  static String get socketUrl {
     // Remove /api from the end
     return baseUrl.replaceAll('/api', '');
  } 
  
  // Auth Routes
  static String get authLogin => '$baseUrl/auth/login';
  static String get authVerify => '$baseUrl/auth/verify';
  
  // Job Routes
  static String get jobsAvailable => '$baseUrl/jobs/available';
  static String get jobsAccept => '$baseUrl/jobs/accept';
}
