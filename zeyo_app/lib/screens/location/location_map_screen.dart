import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import '../../core/providers/location_provider.dart';
import '../../core/services/location_service.dart';

class LocationMapScreen extends StatefulWidget {
  const LocationMapScreen({super.key});

  @override
  State<LocationMapScreen> createState() => _LocationMapScreenState();
}

class _LocationMapScreenState extends State<LocationMapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final TextEditingController _searchController = TextEditingController();
  
  // Default to Mumbai
  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(19.0760, 72.8777),
    zoom: 16,
  );

  LatLng? _currentCenter;
  String? _selectedAddress;
  String? _selectedLocationName;
  bool _isLoading = false;
  Timer? _debounce;
  List<Map<String, dynamic>> _searchResults = [];
  bool _showSearchResults = false;
  bool _isMoving = false;
  bool _usingCurrentLocation = false;
  bool _isFetchingAddress = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _determinePosition();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 100), () async {
      if (_searchController.text.length >= 3) {
        final results = await LocationService.getPlacePredictions(_searchController.text);
        if (mounted) {
          setState(() {
            _searchResults = results;
            _showSearchResults = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _searchResults = [];
            _showSearchResults = false;
          });
        }
      }
    });
  }

  Future<void> _determinePosition() async {
    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<LocationProvider>(context, listen: false);
      await provider.determinePosition();
      
      if (provider.latitude != null && provider.longitude != null) {
        final latLng = LatLng(provider.latitude!, provider.longitude!);
        
        final controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newLatLng(latLng));
        
        setState(() {
          _currentCenter = latLng;
          _usingCurrentLocation = true;
        });
        await _reverseGeocode(latLng);
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reverseGeocode(LatLng position) async {
    setState(() => _isFetchingAddress = true);
    try {
       // Timeout after 10 seconds to allow for slower networks/emulators
       final details = await LocationService.getLocationDetails(position.latitude, position.longitude)
           .timeout(const Duration(seconds: 10));
           
       if (mounted) {
            setState(() {
              if (details != null) {
                _selectedAddress = details['address'];
                _selectedLocationName = details['name'];
              } else {
                // Fallback for demo/error cases
                _selectedAddress = "Selected Location (Address not found)";
                _selectedLocationName = "Pinned Location";
              }
            });
       }
    } catch (e) {
      debugPrint("Reverse geocode error: $e");
      if (mounted) {
        setState(() {
          // Robust fallback so user can ALWAYS proceed
          _selectedAddress = "Selected Location";
          _selectedLocationName = "Pinned Location";
        });
      }
    } finally {
      if (mounted) setState(() => _isFetchingAddress = false);
    }
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _currentCenter = position.target;
      _isMoving = true;
      _usingCurrentLocation = false; // Moved manually
    });
  }

  void _onCameraIdle() {
    setState(() => _isMoving = false);
    if (_currentCenter != null) {
      _reverseGeocode(_currentCenter!);
    }
  }

  Future<void> _handleSearchResultClick(Map<String, dynamic> result) async {
    setState(() {
      _showSearchResults = false;
      _searchController.clear();
      FocusScope.of(context).unfocus();
    });

    final details = await LocationService.getPlaceDetails(result['place_id']);
    if (details != null && details['geometry'] != null) {
       final lat = details['geometry']['location']['lat'];
       final lng = details['geometry']['location']['lng'];
       final newPos = LatLng(lat, lng);

       final controller = await _controller.future;
       controller.animateCamera(CameraUpdate.newLatLngZoom(newPos, 18));
       
       setState(() {
         _currentCenter = newPos;
         _selectedAddress = details['formatted_address'] ?? result['description'];
         _selectedLocationName = result['structured_formatting']?['main_text'] ?? result['description']; // Use main text from prediction
         _usingCurrentLocation = false;
       });
    }
  }

  void _confirmLocation() {
    if (_currentCenter != null) {
      context.push('/address-details', extra: {
        'latitude': _currentCenter!.latitude,
        'longitude': _currentCenter!.longitude,
        'address': _selectedAddress ?? '',
        'locationName': _selectedLocationName ?? "Selected Location",
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: _defaultPosition,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
          ),

          // Center Pin (Matching React SVG)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 36), // Adjust to point exactly at center
              child: CustomPaint(
                size: const Size(34, 34),
                painter: MapPinPainter(),
                child: const SizedBox(width: 34, height: 34),
              ),
            ),
          ),

          // Search Header Area
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: AppTheme.background.withOpacity(0.95),
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 12,
                    left: 16,
                    right: 16,
                    bottom: 12,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                             onTap: () => context.pop(),
                             child: Container(
                               width: 40,
                               height: 40,
                               decoration: const BoxDecoration(
                                 color: AppTheme.background,
                                 shape: BoxShape.circle,
                                 boxShadow: [
                                   BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                                 ],
                               ),
                               child: const Icon(LucideIcons.arrowLeft, size: 20, color: AppTheme.foreground),
                             ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.background,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                   BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: "Search an area or address",
                                  hintStyle: GoogleFonts.inter(color: AppTheme.mutedForeground),
                                  prefixIcon: const Icon(LucideIcons.search, color: AppTheme.mutedForeground, size: 20),
                                  suffixIcon: _searchController.text.isNotEmpty 
                                    ? IconButton(
                                        icon: const Icon(LucideIcons.x, size: 16),
                                        onPressed: () => _searchController.clear(),
                                      )
                                    : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Search Results dropdown
                      if (_showSearchResults && _searchResults.isNotEmpty)
                        Container(
                           margin: const EdgeInsets.only(top: 8, left: 52),
                           decoration: BoxDecoration(
                             color: AppTheme.background,
                             borderRadius: BorderRadius.circular(12),
                             border: Border.all(color: AppTheme.border),
                             boxShadow: const [
                               BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                             ],
                           ),
                           constraints: const BoxConstraints(maxHeight: 300),
                           child: ListView.builder(
                             padding: EdgeInsets.zero,
                             shrinkWrap: true,
                             itemCount: _searchResults.length,
                             itemBuilder: (context, index) {
                               final result = _searchResults[index];
                               return ListTile(
                                 leading: const Icon(LucideIcons.mapPin, size: 16, color: AppTheme.mutedForeground),
                                 title: Text(
                                   result['description'] ?? '',
                                   style: GoogleFonts.inter(fontSize: 14),
                                   maxLines: 2,
                                   overflow: TextOverflow.ellipsis,
                                 ),
                                 onTap: () => _handleSearchResultClick(result),
                               );
                             },
                           ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom Sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Use Current Location Button (if dragged away)
                    if (!_usingCurrentLocation)
                      Center(
                         child: InkWell(
                          onTap: _determinePosition,
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                             margin: const EdgeInsets.only(bottom: 24),
                             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                             decoration: BoxDecoration(
                               color: Colors.white,
                               borderRadius: BorderRadius.circular(30),
                               border: Border.all(color: const Color(0xFFE2E2E2)),
                               boxShadow: const [
                                 BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                               ],
                             ),
                             child: Row(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 const Icon(LucideIcons.crosshair, size: 18, color: AppTheme.primary), // Revert to primary (Black)
                                 const SizedBox(width: 8),
                                 Text(
                                   "Current Location",
                                   style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.foreground),
                                 ),
                               ],
                             ),
                          ),
                        ),
                      ),
                    
                    Text(
                      "Order will be delivered here",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.mutedForeground,
                        fontWeight: FontWeight.w500
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Location Info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.location_on, color: AppTheme.primary, size: 28), // Revert to primary (Black)
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(
                                 _selectedLocationName ?? "Selected Location",
                                 style: GoogleFonts.inter(
                                   fontSize: 18,
                                   fontWeight: FontWeight.bold,
                                   color: AppTheme.foreground,
                                 ),
                               ),
                               const SizedBox(height: 4),
                               Text(
                                 _selectedAddress ?? "Fetching address...",
                                 style: GoogleFonts.inter(
                                   fontSize: 14,
                                   color: AppTheme.mutedForeground,
                                   height: 1.4
                                 ),
                               ),
                             ],
                          ),
                        )
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (_isLoading || _isMoving || _isFetchingAddress) ? null : _confirmLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary, // Revert to primary (Black)
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading || _isMoving || _isFetchingAddress
                            ? const SizedBox(
                                 height: 24, width: 24,
                                 child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                "Confirm & proceed",
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MapPinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF111111) // Revert to Black
      ..style = PaintingStyle.fill;

    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    
    // Simple oval shadow at the tip
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width / 2, size.height + 2), width: 24, height: 6), 
      shadowPaint,
    );

    // SVG Path: M12 2C8.686 2 6 4.686 6 8c0 4.5 6 12 6 12s6-7.5 6-12c0-3.314-2.686-6-6-6z
    // The SVG viewport is 24x24. We scale it to 34x34.
    // Scale factor = 34/24 = 1.4166
    
    canvas.save();
    canvas.scale(34/24, 34/24);
    
    final path = Path();
    path.moveTo(12, 2);
    path.cubicTo(8.686, 2, 6, 4.686, 6, 8);
    path.cubicTo(6, 12.5, 12, 20, 12, 20);
    path.cubicTo(12, 20, 18, 12.5, 18, 8);
    path.cubicTo(18, 4.686, 15.314, 2, 12, 2);
    path.close();
    
    canvas.drawPath(path, paint);
    
    // Inner white circle cx="12" cy="8.5" r="2.5"
    final circlePaint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(12, 8.5), 2.5, circlePaint);
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
