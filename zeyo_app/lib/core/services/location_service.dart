import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LocationService {
  static String get _googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? ""; 

  static Future<Position?> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  static String _getProxiableUrl(String url) {
    if (kIsWeb) {
      // CORS Anywhere demo or similar might be needed if not using JS SDK
      return 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(url)}';
    }
    return url;
  }

  // Still uses HTTP for Autocomplete (might need separate fix if this fails too)
  static Future<List<Map<String, dynamic>>> getPlacePredictions(String query) async {
    if (query.isEmpty) return [];

    final urlString = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$_googleMapsApiKey&components=country:in';
    final url = Uri.parse(_getProxiableUrl(urlString));

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return List<Map<String, dynamic>>.from(data['predictions']);
        }
      }
    } catch (e) {
      debugPrint('Error fetching predictions: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    final urlString = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_googleMapsApiKey';
    final url = Uri.parse(_getProxiableUrl(urlString));

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data['result'];
        }
      }
    } catch (e) {
      debugPrint('Error fetching place details: $e');
    }
    return null;
  }

  static Future<Map<String, String>?> getLocationDetails(double lat, double lng) async {
    try {
      debugPrint('Fetching location for $lat, $lng using native geocoding...');
      
      // Use the geocoding package which handles platform channels (Android/iOS) and JS SDK (Web)
      // This bypasses CORS issues on Web since it uses the loaded Google Maps script
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        
        // Construct a formatted address
        // Typical format: Street, SubLocality, Locality, PostalCode, Country
        final components = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.postalCode
        ].where((e) => e != null && e.isNotEmpty).toSet().toList(); // toSet removes duplicates
        
        final formattedAddress = components.join(', ');
        
        // Extract a meaningful name
        String name = place.name ?? place.subLocality ?? place.locality ?? "Selected Location";
        // Clean up if name is just "24" or pure numbers
        if (RegExp(r'^\d+$').hasMatch(name) || name.isEmpty) {
           name = place.subLocality ?? place.locality ?? place.street ?? "Selected Location";
        }

        debugPrint('Location found: $name, $formattedAddress');
        
        return {
          'address': formattedAddress,
          'name': name
        };
      }
    } catch (e) {
      debugPrint('Error fetching location details (native): $e');
      
      // Fallback: If native/package fails (e.g. on some emulators), try HTTP strictly for debugging
      // But avoid it on Web to prevent CORS spam
      if (!kIsWeb) {
         return await _getLocationDetailsHttp(lat, lng);
      }
    }
    
    // Final Fallback
    return {
       'address': "Address not found (Check Internet/API Key)", 
       'name': "Selected Location" 
    };
  }
  
  // Legacy HTTP method kept as backup for Android Emulators without Play Services
  static Future<Map<String, String>?> _getLocationDetailsHttp(double lat, double lng) async {
    final urlString = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$_googleMapsApiKey';
    final url = Uri.parse(urlString); // No proxy needed for mobile

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
           final result = data['results'][0];
           return {
             'address': result['formatted_address'],
             'name': "Selected Location" // Simplification for fallback
           };
        }
      }
    } catch (e) {
      debugPrint('HTTP Fallback error: $e');
    }
    return null;
  }
}
