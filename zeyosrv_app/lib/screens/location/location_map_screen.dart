import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:zeyosrv_app/core/theme/app_theme.dart';
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
    _debounce = Timer(const Duration(milliseconds: 300), () async {
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
    try {
       final details = await LocationService.getLocationDetails(position.latitude, position.longitude);
       if (mounted && details != null) {
            setState(() {
              _selectedAddress = details['address'];
              _selectedLocationName = details['name'];
            });
       }
    } catch (e) {
      debugPrint("Reverse geocode error: $e");
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
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                border: Border(top: BorderSide(color: AppTheme.border)),
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
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 20),
                             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                             decoration: BoxDecoration(
                               color: AppTheme.background,
                               borderRadius: BorderRadius.circular(12),
                               border: Border.all(color: AppTheme.border),
                               boxShadow: const [
                                 BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
                               ],
                             ),
                             child: Row(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 const Icon(LucideIcons.navigation, size: 16, color: Colors.black),
                                 const SizedBox(width: 8),
                                 Text(
                                   "Current Location",
                                   style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                                 ),
                               ],
                             ),
                          ),
                        ),
                      ),
                    
                    Center(
                      child: Text(
                        "Move the map to position the pointer at your exact location",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 13, color: AppTheme.mutedForeground),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Selected Location Card
                    Container(
                      padding: const EdgeInsets.all(16),
                       decoration: BoxDecoration(
                         color: AppTheme.card,
                         border: Border.all(color: AppTheme.border),
                         borderRadius: BorderRadius.circular(12),
                       ),
                       child: Row(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                            Container(
                               width: 24, height: 24,
                               decoration: const BoxDecoration(
                                 color: AppTheme.foreground,
                                 shape: BoxShape.circle,
                               ),
                               child: Center(
                                 child: Container(
                                   width: 8, height: 8,
                                   decoration: const BoxDecoration(
                                     color: AppTheme.background,
                                     shape: BoxShape.circle,
                                   ),
                                 ),
                               ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Row(
                                      children: [
                                        const Icon(LucideIcons.navigation, size: 16, color: AppTheme.foreground),
                                        const SizedBox(width: 6),
                                        Text(
                                          _selectedLocationName ?? "Selected Location",
                                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                                        ),
                                      ],
                                   ),
                                   const SizedBox(height: 4),
                                   Text(
                                     _selectedAddress ?? "Loading...",
                                      style: GoogleFonts.inter(fontSize: 14, color: AppTheme.mutedForeground),
                                   ),
                                 ],
                               ),
                            ),
                         ],
                       ),
                    ),
                    
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: (_isLoading || _isMoving) ? null : _confirmLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading || _isMoving
                          ? const SizedBox(
                               height: 20, width: 20,
                               child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              "Confirm & proceed",
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(height: 10), // Safe area breathing room
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
      ..color = const Color(0xFF111111)
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
