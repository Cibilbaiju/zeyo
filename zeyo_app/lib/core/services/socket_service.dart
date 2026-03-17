import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'auth_service_backend.dart';
import '../constants/api_constants.dart';

class SocketService {
  static IO.Socket? socket;
  
  // Stream controllers for job updates
  static final _jobUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  static Stream<Map<String, dynamic>> get jobUpdateStream => _jobUpdateController.stream;

  // Initialize Socket Connection
  static Future<void> initSocket() async {
    final token = await AuthServiceBackend.getToken();
    if (token == null) {
      debugPrint('[Socket] No token available, skipping socket init');
      return;
    }

    // Connect to backend with proper auth
    socket = IO.io(ApiConstants.socketUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': token}) // Proper JWT auth for socket.io
        .setExtraHeaders({'Authorization': 'Bearer $token'})
        .disableAutoConnect()
        .enableReconnection()
        .build());

    socket?.connect();

    socket?.onConnect((_) {
      debugPrint('[Socket] ✅ User Socket Connected! ID: ${socket?.id}');
    });

    socket?.onConnectError((error) {
      debugPrint('[Socket] ❌ Connection Error: $error');
    });

    socket?.onDisconnect((_) => debugPrint('[Socket] ⚠️ User Socket Disconnected'));
    
    // Listen for job updates (when provider accepts/completes)
    socket?.on('job:update', (data) {
      debugPrint('[Socket] 📦 Job Update: $data');
      if (data is Map) {
        _jobUpdateController.add(Map<String, dynamic>.from(data));
      }
    });

    // Listen for job status updates
    socket?.on('job:status', (data) {
      debugPrint('[Socket] 📦 Job Status: $data');
      if (data is Map) {
        _jobUpdateController.add(Map<String, dynamic>.from(data));
      }
    });
  }

  static void subscribeToJob(String jobId) {
    debugPrint('[Socket] Subscribing to job: $jobId');
    socket?.emit('job:subscribe', jobId);
  }

  static void dispose() {
    _jobUpdateController.close();
  }
}

