import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/providers/location_provider.dart';
import '../../core/theme/app_theme.dart';

class SearchingServiceScreen extends StatefulWidget {
  final String serviceName;
  
  const SearchingServiceScreen({
    super.key, 
    required this.serviceName,
  });

  @override
  State<SearchingServiceScreen> createState() => _SearchingServiceScreenState();
}

class _SearchingServiceScreenState extends State<SearchingServiceScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  String _mapStyle = '';
  
  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _generateRandomProviders();
  }

  Future<void> _loadMapStyle() async {
    try {
      // Use standard style or a custom simple one if available
      // _mapStyle = await rootBundle.loadString('assets/map_style.json');
    } catch (e) {
      debugPrint("Failed to load map style");
    }
  }

  void _generateRandomProviders() {
    // We will generate these once we have the user location
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_mapStyle.isNotEmpty) {
      controller.setMapStyle(_mapStyle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final currentPos = LatLng(
      locationProvider.latitude ?? 12.9716, // Default Bangalore
      locationProvider.longitude ?? 77.5946,
    );

    // Generate markers if not exists and we have location
    if (_markers.isEmpty && locationProvider.latitude != null) {
      final random = Random();
      final newMarkers = <Marker>{};
      
      // Create user marker
       newMarkers.add(
         Marker(
           markerId: const MarkerId('user'),
           position: currentPos,
           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
         ),
       );

      // Create 3-4 random provider markers nearby
      for (int i = 0; i < 4; i++) {
        // Random offset ~0.005 degrees (approx 500m)
        final latOffset = (random.nextDouble() - 0.5) * 0.01; 
        final lngOffset = (random.nextDouble() - 0.5) * 0.01;
        
        newMarkers.add(
          Marker(
            markerId: MarkerId('provider_$i'),
            position: LatLng(currentPos.latitude + latOffset, currentPos.longitude + lngOffset),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange), // Service provider color
            // In a real app, this would be a custom icon (e.g. car or tool icon)
          ),
        );
      }
      _markers = newMarkers;
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. Google Map Background
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: currentPos,
              zoom: 14.5,
            ),
            markers: _markers,
            myLocationEnabled: false, // We use custom marker or standard
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // 2. Back Button
          Positioned(
             top: 50,
             left: 16,
             child: InkWell(
               onTap: () => context.pop(),
               child: Container(
                 padding: const EdgeInsets.all(8),
                 decoration: const BoxDecoration(
                   color: Colors.white,
                   shape: BoxShape.circle,
                   boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                 ),
                 child: const Icon(Icons.arrow_back, size: 24),
               ),
             ),
          ),

          // 3. Bottom Finding UI
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Status Text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Requesting ${widget.serviceName}",
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Finding experts nearby...",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ).animate(onPlay: (controller) => controller.repeat())
                        .shimmer(duration: 2000.ms, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Progress Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue), // Uber-like blue
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Location Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white, // Bordered style
                        border: Border.all(color: Colors.grey[200]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                             padding: const EdgeInsets.all(8),
                             decoration: BoxDecoration(
                               color: Colors.grey[100],
                               shape: BoxShape.circle,
                             ),
                             child: const Icon(LucideIcons.mapPin, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Address details",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  locationProvider.address ?? "Select location",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                           Container(
                             padding: const EdgeInsets.all(8),
                             decoration: BoxDecoration(
                               color: Colors.grey[100],
                               borderRadius: BorderRadius.circular(8),
                             ),
                             child: const Icon(Icons.more_horiz, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Promotional/Info Section "Quality rides" style
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        _buildInfoCard(
                          color: const Color(0xFFFFF4E0), // Light Orange
                          image: "assets/images/quality.png", // Use icon if no image
                          title: "Top Rated Experts",
                          subtitle: "4.8+ rated professionals",
                        ),
                        const SizedBox(width: 12),
                        _buildInfoCard(
                          color: const Color(0xFFE0F7FA), // Light Cyan
                          image: "assets/images/safety.png",
                          title: "Verified Pros",
                          subtitle: "Background checked",
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required Color color,
    required String image,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
               color: Colors.white,
               shape: BoxShape.circle,
            ),
             // Just using an icon for now as I don't have assets
            child: const Icon(LucideIcons.shieldCheck, size: 24, color: Colors.black),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
