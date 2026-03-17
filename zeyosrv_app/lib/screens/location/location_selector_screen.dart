import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:zeyosrv_app/core/theme/app_theme.dart';
import '../../core/providers/location_provider.dart';
import '../../core/services/location_service.dart';
import '../../core/services/address_service.dart';


class LocationSelectorScreen extends StatefulWidget {
  const LocationSelectorScreen({super.key});

  @override
  State<LocationSelectorScreen> createState() => _LocationSelectorScreenState();
}

class _LocationSelectorScreenState extends State<LocationSelectorScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _predictions = [];
  Timer? _debounce;
  bool _isLoadingCurrentLocation = false;
  bool _hasSavedAddresses = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _checkSavedAddresses();
  }

  Future<void> _checkSavedAddresses() async {
    final addresses = await AddressService.getAddresses();
    if (mounted) {
      setState(() {
        _hasSavedAddresses = addresses.isNotEmpty;
      });
    }
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
      if (_searchController.text.isNotEmpty) {
        final results = await LocationService.getPlacePredictions(_searchController.text);
        if (mounted) {
          setState(() {
            _predictions = results;
          });
        }
      } else {
        setState(() {
          _predictions = [];
        });
      }
    });
  }

  Future<void> _handleUseCurrentLocation() async {
    setState(() => _isLoadingCurrentLocation = true);
    try {
      await Provider.of<LocationProvider>(context, listen: false).determinePosition();
      if (mounted) context.pop();
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoadingCurrentLocation = false);
    }
  }

  Future<void> _handlePredictionClick(String placeId, String description) async {
    // For now, just setting the address description as the location
    // Ideally, catch details to get lat/long
    
    // Simulating fetching details
    final details = await LocationService.getPlaceDetails(placeId);
    if (details != null && details['geometry'] != null) {
       final lat = details['geometry']['location']['lat'];
       final lng = details['geometry']['location']['lng'];
       
       if (mounted) {
         Provider.of<LocationProvider>(context, listen: false).setLocation(
           description, 
           lat, 
           lng,
           label: description.split(',')[0].trim()
         );
         context.pop();
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.arrowLeft, size: 24),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Enter area or apartment",
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.foreground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  const SizedBox(height: 16),
                  

                ],
              ),
            ),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_predictions.isNotEmpty) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        children: _predictions.map((p) => _buildPredictionItem(p)).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Use Current Location Button
                  InkWell(
                    onTap: _handleUseCurrentLocation,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.navigation, color: AppTheme.foreground),
                              const SizedBox(width: 12),
                              Text(
                                "Use my current location",
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.foreground,
                                ),
                              ),
                            ],
                          ),
                          if (_isLoadingCurrentLocation)
                            const SizedBox(
                              width: 20, 
                              height: 20, 
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)
                            )
                        ],
                      ),
                    ),
                  ),

                  // Add New Address Button
                  InkWell(
                    onTap: () {
                      context.push('/location-map');
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.plus, color: AppTheme.foreground),
                          const SizedBox(width: 12),
                          Text(
                            "Add a new address",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.foreground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Saved Addresses Section
                  const SizedBox(height: 24),
                  Text(
                    "SAVED ADDRESSES",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.mutedForeground,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Real Saved Addresses
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _fetchSavedAddresses(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      if (snapshot.data!.isEmpty) return const SizedBox.shrink();

                      return Column(
                        children: snapshot.data!.map((addr) {
                          return _buildSavedAddressItem(addr);
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchSavedAddresses() async {
    final addresses = await AddressService.getAddresses();
    return addresses.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  void _showActionSheet(Map<String, dynamic> address) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                address['label'] ?? 'Address',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                address['address_line'] ?? '',
                style: GoogleFonts.inter(fontSize: 14, color: AppTheme.mutedForeground),
              ),
              const SizedBox(height: 24),
              _buildActionItem(LucideIcons.edit, "Edit", () {
                context.pop(); // Close sheet
                context.push('/address-details', extra: {
                  'editMode': true,
                  'addressId': address['id'],
                  'currentLabel': address['label'],
                  'address_line': address['address_line'],
                  'latitude': address['latitude'],
                  'longitude': address['longitude'],
                  'currentHouseFloor': address['house_flat_floor'],
                  'currentApartmentArea': address['apartment_road_area'],
                  'currentDirections': address['directions'] is String ? address['directions'] : null, // Handle potential JSON object if driver converts
                });
              }),
              _buildActionItem(LucideIcons.share2, "Share", () {
                context.pop();
                // TODO: Implement Share
              }),
              _buildActionItem(LucideIcons.trash2, "Delete", () {
                context.pop();
                _confirmDelete(address['id']);
              }, isDestructive: true),
            ],
          ),
        ),
      ),
    );
  }
  
  void _confirmDelete(String id) {
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         icon: const Icon(LucideIcons.alertTriangle, color: AppTheme.destructive),
         title: const Text('Delete Address?'),
         content: const Text('Are you sure you want to delete this address? This action cannot be undone.'),
         actions: [
           TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
           TextButton(
             onPressed: () async {
               context.pop();
               await AddressService.deleteAddress(id);
               if (mounted) setState(() {});
             },
             child: const Text('Delete', style: TextStyle(color: AppTheme.destructive)),
           ),
         ],
       ),
     );
  }

  Widget _buildActionItem(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        width: double.infinity,
        child: Row(
          children: [
            Icon(icon, color: isDestructive ? AppTheme.destructive : AppTheme.foreground, size: 20),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDestructive ? AppTheme.destructive : AppTheme.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedAddressItem(Map<String, dynamic> address) {
    IconData icon = LucideIcons.tag;
    final label = (address['label'] as String?)?.toLowerCase() ?? '';
    if (label == 'home') icon = LucideIcons.home;
    else if (label == 'work') icon = LucideIcons.briefcase;
    else if (label.contains('friend')) icon = LucideIcons.users;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address['label'] ?? '',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.foreground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address['address_line'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => _showActionSheet(address),
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(LucideIcons.moreVertical, size: 20, color: AppTheme.mutedForeground),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionItem(Map<String, dynamic> prediction) {
    return InkWell(
      onTap: () => _handlePredictionClick(prediction['place_id'], prediction['description']),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(LucideIcons.mapPin, size: 20, color: AppTheme.mutedForeground),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prediction['structured_formatting']['main_text'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.foreground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    prediction['structured_formatting']['secondary_text'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
