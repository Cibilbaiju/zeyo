import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';
import 'auth_service.dart';

class LocationService {
  static IO.Socket? socket;
  static bool isTracking = false;

  static final _jobOfferController = StreamController<Map<String, dynamic>>.broadcast();
  static Stream<Map<String, dynamic>> get jobOfferStream => _jobOfferController.stream;

  static final _socketStatusController = StreamController<String>.broadcast();
  static Stream<String> get socketStatusStream => _socketStatusController.stream;

  // Initialize Socket Connection
  static Future<void> initSocket() async {
    final token = await AuthService.getToken();
    if (token == null) {
      _socketStatusController.add('ERROR: No Token');
      return;
    }

    _socketStatusController.add('Initializing...');
    
    // Replace localhost with IP if on physical device
    socket = IO.io(ApiConstants.socketUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': token}) // Standard Auth Payload
        .setExtraHeaders({'Authorization': 'Bearer $token'}) // Keep for compatibility if needed
        .disableAutoConnect()
        .enableReconnection()
        .build());

    socket?.connect();

    socket?.onConnect((_) {
      print('[Socket] ✅ CONNECTED! Socket ID: ${socket?.id}');
      _socketStatusController.add('CONNECTED (${socket?.id})');
    });

    socket?.onConnectError((error) {
      print('[Socket] ❌ CONNECTION ERROR: $error');
      _socketStatusController.add('ERROR: $error');
    });

    socket?.onDisconnect((_) {
      print('[Socket] ⚠️ Disconnected');
      _socketStatusController.add('Disconnected');
    });
    
    socket?.on('error', (data) {
      print('[Socket] ❌ Socket Error Event: $data');
      _socketStatusController.add('Socket Error: $data');
    });

    // Listen for New Jobs
    socket?.on('job:new', (data) {
      print('[Socket] 🎉 NEW JOB OFFER RECEIVED: $data');
      _socketStatusController.add('JOB RECEIVED!');
      _jobOfferController.add(Map<String, dynamic>.from(data));
    });
  }

  // Start watching position and emitting updates
  static Future<void> startTracking() async {
    if (isTracking) return;
    
    print('[Location] Requesting permissions...');
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('[Location] Permission denied');
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      print('[Location] Permission denied forever');
      return;
    }

    isTracking = true;
    print('[Location] Starting tracking...');

    // Ensure Socket Connected
    if (socket == null) {
      await initSocket();
    } else if (socket!.disconnected) {
      socket!.connect();
    }

    // FORCE INITIAL LOCATION UPDATE
    try {
      // 1. Try Last Known (Fast)
      Position? position = await Geolocator.getLastKnownPosition();

      // 2. If null, Try Current (Accurate)
      if (position == null) {
          position = await Geolocator.getCurrentPosition(
            timeLimit: const Duration(seconds: 10)
          );
      }

      print('[Location] Initial Position: ${position.latitude}, ${position.longitude}');
      if (socket != null && socket!.connected) {
        socket?.emit('technician:location', {
          'lat': position.latitude, 
          'lng': position.longitude,
          'status': 'online',
        });
      }
    } catch (e) {
      print('[Location] Error getting initial position: $e');
      // No fallback! We want accurate location.
    }

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, 
      ),
    ).listen((Position position) {
      if (socket != null && socket!.connected) {
        print('[Location] Stream sending: ${position.latitude}, ${position.longitude}');
        socket?.emit('technician:location', {
          'lat': position.latitude, 
          'lng': position.longitude,
          'status': 'online',
        });
      }
    }, onError: (e) {
       print('[Location] Stream Error: $e');
    });
  }

  static void stopTracking() {
    isTracking = false;
    
    if (socket != null && socket!.connected) {
      print('[Location] Sending Offline Status...');
      socket?.emit('technician:location', {
        'lat': 0.0,
        'lng': 0.0,
        'status': 'offline',
      });
      // Allow specific time for event to flush before cutting connection
      Future.delayed(const Duration(milliseconds: 500), () {
        socket?.disconnect();
      });
    } else {
      socket?.disconnect();
    }
  }

  // --- Restored Methods for Compatibility ---

  static Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition();
  }

  static Future<Map<String, dynamic>> getLocationDetails(double lat, double lng) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'formatted_address': '123 Verified Loc, Panvel',
      'geometry': {'location': {'lat': lat, 'lng': lng}}
    };
  }

  static Future<List<Map<String, dynamic>>> getPlacePredictions(String query) async {
     return [];
  }

  static Future<Map<String, dynamic>> getPlaceDetails(String placeId) async {
    return {
      'formatted_address': '123 Mock Place, Panvel',
      'geometry': {
        'location': {'lat': 18.9894, 'lng': 73.1175} // Panvel Coords
      }
    };
  }
}
