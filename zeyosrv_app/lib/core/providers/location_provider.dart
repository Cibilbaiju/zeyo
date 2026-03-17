import 'package:flutter/material.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class LocationProvider extends ChangeNotifier {
  String? _address;
  double? _latitude;
  double? _longitude;
  String? _label;
  bool _isLoading = false;

  String? get address => _address;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  String? get label => _label;
  bool get isLoading => _isLoading;

  Future<void> determinePosition() async {
    _isLoading = true;
    notifyListeners();

    try {
      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        _latitude = position.latitude;
        _longitude = position.longitude;
        
        final details = await LocationService.getLocationDetails(position.latitude, position.longitude);
        if (details != null) {
           _address = details['address'];
           _label = details['name'];
        }
      }
    } catch (e) {
      print("Error getting location: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setLocation(String address, double lat, double lng, {String? label}) {
    _address = address;
    _latitude = lat;
    _longitude = lng;
    _label = label;
    notifyListeners();
  }
}
