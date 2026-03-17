import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:action_slider/action_slider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/location_service.dart';
import '../../core/services/api_service.dart';
import '../../core/services/socket_service.dart';
import '../../core/constants/api_constants.dart';
import './widgets/job_offer_bottom_sheet.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  bool _isOnline = false;
  Map<String, dynamic>? _stats;
  StreamSubscription? _jobSubscription;
  bool _jobSheetOpen = false;
  GoogleMapController? _mapController;
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(18.9894, 73.1175), // Default Panvel (User Request)
    zoom: 15,
  );
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initSocket();
    _fetchStats();
    _getCurrentLocationForMap();
  }

  Future<void> _getCurrentLocationForMap() async {
    try {
      // 1. Try Last Known (Fast)
      Position? pos = await Geolocator.getLastKnownPosition();
      
      // 2. If null, Try Current (Accurate) with shorter timeout then handling
      if (pos == null) {
          pos = await Geolocator.getCurrentPosition(
            timeLimit: const Duration(seconds: 10)
          );
      }

      setState(() {
        _initialCameraPosition = CameraPosition(
          target: LatLng(pos!.latitude, pos.longitude),
          zoom: 16,
        );
        _markers = {
          Marker(
            markerId: const MarkerId('me'),
            position: LatLng(pos.latitude, pos.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          )
        };
      });
      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLng(LatLng(pos!.latitude, pos.longitude)));
      }
    } catch (e) {
      print('Error getting initial map loc: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('GPS Timeout. Using default location (Panvel). Check permissions.'))
        );
      }
    }
  }

  Future<void> _initSocket() async {
    await LocationService.initSocket();
    _jobSubscription = LocationService.jobOfferStream.listen((data) {
        if (mounted) {
            _showJobOfferDialog(data);
        }
    });
  }

  Future<void> _fetchStats() async {
    try {
      final response = await ApiService.get('${ApiConstants.baseUrl}/technician/stats');
      if (response != null && response is Map<String, dynamic>) {
        setState(() {
          _stats = response;
        });
      }
    } catch (e) {
      print('Stats fetch error: $e'); 
    }
  }

  Future<void> _toggleOnlineStatus(ActionSliderController controller) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enable Location Services.')));
        controller.reset();
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
       permission = await Geolocator.requestPermission();
       if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission is required.')));
            controller.reset();
          }
          return;
       }
    }

    setState(() {
      _isOnline = true;
    });
    
    await LocationService.startTracking();
    _getCurrentLocationForMap();
  }

  void _goOffline() {
    LocationService.stopTracking();
    setState(() {
      _isOnline = false;
    });
  }

  Future<bool> _acceptJob(Map<String, dynamic> jobData) async {
    try {
      // Get the technician ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final technicianId = prefs.getString('tech_id');
      
      if (technicianId == null) {
        debugPrint('[Job Accept] No technician ID found!');
        return false;
      }

      final jobId = jobData['jobId'];
      if (jobId == null) {
        debugPrint('[Job Accept] No job ID in data!');
        return false;
      }

      debugPrint('[Job Accept] Accepting job $jobId as technician $technicianId');

      // Call the backend API
      final response = await ApiService.post(
        '${ApiConstants.baseUrl}/jobs/accept',
        {
          'jobId': jobId,
          'technicianId': technicianId,
        },
      );

      if (response != null && response['success'] == true) {
        debugPrint('[Job Accept] ✅ Success! OTP: ${response['otp']}');
        return true;
      } else {
        debugPrint('[Job Accept] ❌ Failed: $response');
        return false;
      }
    } catch (e) {
      debugPrint('[Job Accept] ❌ Error: $e');
      return false;
    }
  }

  void _showJobOfferDialog(dynamic data) {
    if (_jobSheetOpen) return;
    _jobSheetOpen = true;
    final jobData = Map<String, dynamic>.from(data);
    showModalBottomSheet(
      context: context, 
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (ctx) => JobOfferBottomSheet(
        jobData: jobData,
        onAccept: () => _acceptJob(jobData),
        onDecline: () { Navigator.pop(ctx); },
      )
    ).whenComplete(() {
      _jobSheetOpen = false;
    });
  }


  @override
  void dispose() {
    _jobSubscription?.cancel();
    if (!_isOnline) {
       LocationService.stopTracking(); 
    }
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isOnline) {
      return _buildOnlineUI();
    } else {
      return _buildOfflineUI();
    }
  }

  Widget _buildOfflineUI() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Start earning', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none, color: Colors.black)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(Icons.star, '5.0', 'Ratings', Colors.orange),
                _buildStatItem(Icons.account_balance_wallet, '₹${_stats?['earnings_today'] ?? '0'}', 'Today', Colors.green),
                _buildStatItem(Icons.work, _stats?['completed_orders'] ?? '0', 'Jobs', Colors.blue),
              ],
            ),
            const SizedBox(height: 30),
            
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F9F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text('Weekly Earnings Graph', style: GoogleFonts.inter(color: Colors.grey)),
              ),
            ),
            
            const Spacer(),
            
            ActionSlider.standard(
              sliderBehavior: SliderBehavior.stretch,
              rolling: true,
              width: double.infinity,
              backgroundColor: Colors.white,
              toggleColor: const Color(0xFF1E1E1E),
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
              successIcon: const Icon(Icons.check, color: Colors.white),
              child: Text('Swipe to Go Online', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
              action: (controller) async {
                controller.loading(); 
                try {
                   await _toggleOnlineStatus(controller);
                   
                   // PROOF OF GPS
                   final pos = await Geolocator.getLastKnownPosition();
                   if (mounted && pos != null) {
                       ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(
                               content: Text('GPS Active: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)} (Using Device Sensors)'),
                               backgroundColor: Colors.green,
                               duration: const Duration(seconds: 4),
                           )
                       );
                   }
                   controller.success();
                } catch (e) {
                   controller.reset();
                   if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineUI() {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Full Screen Map
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false, // Cleaner UI
            onMapCreated: (controller) => _mapController = controller,
            markers: _markers,
          ),

          // 2. Top Status Bar (SafeArea)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Left: Online Indication
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                       decoration: BoxDecoration(
                         color: Colors.white,
                         borderRadius: BorderRadius.circular(30),
                         boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
                       ),
                       child: Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           Container(
                             width: 10, height: 10,
                             decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                           ),
                           const SizedBox(width: 8),
                           Text("ONLINE", style: GoogleFonts.inter(color: Colors.green, fontWeight: FontWeight.bold, letterSpacing: 1)),
                         ],
                       ),
                     ),

                     // Top Right: Go Offline Button
                     Column(
                       crossAxisAlignment: CrossAxisAlignment.end,
                       children: [
                          CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 22,
                            child: IconButton(
                              icon: const Icon(Icons.power_settings_new, color: Colors.red),
                              onPressed: _goOffline,
                              tooltip: 'Go Offline',
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Connection Status Indicator (Optional but helpful)
                          StreamBuilder<String>(
                             stream: LocationService.socketStatusStream,
                             builder: (context, snapshot) {
                               final status = snapshot.data ?? '';
                               if (status.isEmpty) return const SizedBox.shrink();
                               // Only show distinct error state maybe? Or tiny dot?
                               return Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                 decoration: BoxDecoration(
                                   color: Colors.black54,
                                   borderRadius: BorderRadius.circular(12)
                                 ),
                                 child: Text(
                                   status.contains("CONNECTED") ? "Connected" : "Reconnecting...", 
                                   style: GoogleFonts.inter(color: Colors.white, fontSize: 10)
                                 ),
                               );
                             }
                          )
                       ],
                     )
                  ],
                ),
              ),
            ),
          ),
          
          // 3. Bottom: Finding Services Text (Floating Card)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))]
              ),
              child: Row(
                children: [
                   const SizedBox(
                     height: 24, 
                     width: 24, 
                     child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black)
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Text(
                       "Finding nearby services...", 
                       style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)
                     ),
                   )
                ],
              ),
            ),
          )
        ],
      )
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        CircleAvatar(radius: 24, backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 24)),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
