import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import '../../core/providers/location_provider.dart';
import 'package:flutter_app/core/services/address_service.dart';

class AddressDetailsScreen extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final String? addressLine;
  final bool editMode;
  final String? addressId;
  final String? currentLabel;
  final String? currentHouseFloor;
  final String? currentApartmentArea;
  final String? currentLocationName;
  final String? currentDirections;

  const AddressDetailsScreen({
    super.key,
    this.latitude,
    this.longitude,
    this.addressLine,
    this.editMode = false,
    this.addressId,
    this.currentLabel,
    this.currentHouseFloor,
    this.currentApartmentArea,
    this.currentDirections,
    this.currentLocationName,
  });

  @override
  State<AddressDetailsScreen> createState() => _AddressDetailsScreenState();
}

class _AddressDetailsScreenState extends State<AddressDetailsScreen> {
  late TextEditingController _houseController;
  late TextEditingController _apartmentController;
  late TextEditingController _directionsController;
  late TextEditingController _customLabelController;
  late TextEditingController _clientNameController;
  late TextEditingController _clientPhoneController;

  String _selectedPreset = 'Home'; // Default to Home as requested
  bool _saving = false;
  List<String> _existingLabels = [];
  bool _savedHome = false;
  bool _savedWork = false;

  @override
  void initState() {
    super.initState();
    _houseController = TextEditingController(text: widget.currentHouseFloor);
    // Pre-fill with address line if no specific apartment area provided, as requested
    // Ensure it's not coordinates or "Unknown Road" if possible, but addressLine is best we have
    _apartmentController = TextEditingController(text: widget.currentApartmentArea ?? widget.addressLine);
    
    // Parse directions metadata
    String note = "";
    String clientName = "";
    String clientPhone = "";

    if (widget.editMode && widget.currentDirections != null) {
      try {
        final decoded = jsonDecode(widget.currentDirections!);
        if (decoded is Map<String, dynamic>) {
           note = decoded['note']?.toString() ?? "";
           clientName = decoded['clientName']?.toString() ?? "";
           clientPhone = decoded['clientPhone']?.toString() ?? "";
        }
      } catch (e) {
        note = widget.currentDirections!;
      }
    }

    _directionsController = TextEditingController(text: note);
    _clientNameController = TextEditingController(text: clientName);
    _clientPhoneController = TextEditingController(text: clientPhone);
    
    // Determine initial preset
    if (widget.currentLabel != null) {
      final lower = widget.currentLabel!.toLowerCase();
      if (lower == 'home') _selectedPreset = 'Home';
      else if (lower == 'work') _selectedPreset = 'Work';
      else if (lower.contains('friend')) _selectedPreset = 'Friends';
      else _selectedPreset = 'Other';
      
      _customLabelController = TextEditingController(text: _selectedPreset == 'Other' ? widget.currentLabel : '');
    } else {
      _selectedPreset = 'Home'; // Default to Home if new
      _customLabelController = TextEditingController();
    }

    _loadExistingData();
  }

  @override
  void dispose() {
    _houseController.dispose();
    _apartmentController.dispose();
    _directionsController.dispose();
    _customLabelController.dispose();
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingData() async {
    try {
      final data = await AddressService.getAddresses();
      
      // Filter out current address if editing
      final filtered = widget.editMode 
          ? data.where((addr) => addr['id'] != widget.addressId).toList()
          : data;
          
      final labels = filtered.map((addr) => (addr['label'] as String).toLowerCase()).toList();
      
      if (mounted) {
        setState(() {
          _existingLabels = labels;
          _savedHome = labels.contains('home');
          _savedWork = labels.contains('work');
          
            // If default selection is already taken, switch to Other
          if (_selectedPreset == 'Home' && _savedHome && !widget.editMode) _selectedPreset = 'Other';
          if (_selectedPreset == 'Work' && _savedWork && !widget.editMode) _selectedPreset = 'Other';
        });
      }
    } catch (e) {
      debugPrint('Error loading existing data: $e');
    }
  }

  // ... (rest of the file)

  void _handlePresetSelect(String preset) {
    if (preset == 'Home' && _savedHome && !widget.editMode) return;
    if (preset == 'Work' && _savedWork && !widget.editMode) return;

    setState(() {
      _selectedPreset = preset;
      if (preset == 'Home' || preset == 'Work') {
        _customLabelController.text = preset;
        _clientNameController.clear();
        _clientPhoneController.clear();
      } else if (preset == 'Friends') {
        _customLabelController.text = 'Friends and Family';
      } else {
        _clientNameController.clear();
        // Keep custom label if switching to Other
      }
    });
  }

  Future<void> _handleSave() async {
    if (_houseController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter House / Flat / Floor No.')),
      );
      return;
    }

    final customLabel = _customLabelController.text.trim();
    String resolvedLabel = customLabel;
    
    if (_selectedPreset == 'Home') resolvedLabel = 'Home';
    if (_selectedPreset == 'Work') resolvedLabel = 'Work';
    if (_selectedPreset == 'Friends') resolvedLabel = 'Friends and Family';
    if (_selectedPreset == 'Other' && customLabel.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a label for the address')),
      );
      return;
    }

    if (_selectedPreset == 'Friends') {
      if (_clientNameController.text.trim().isEmpty || _clientPhoneController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Client name and phone are required for Friends.')),
        );
        return;
      }
    }

    setState(() => _saving = true);

    try {
      final directionsPayload = jsonEncode({
        'note': _directionsController.text.trim(),
        'clientName': _clientNameController.text.trim(),
        'clientPhone': _clientPhoneController.text.trim(),
      });

      bool success = false;
      if (widget.editMode && widget.addressId != null) {
        // Update
        success = await AddressService.updateAddress(widget.addressId!, {
          'label': resolvedLabel,
          'house_floor': _houseController.text.trim(),
          'apartment_area': _apartmentController.text.trim(),
          'directions': directionsPayload,
          'latitude': widget.latitude,
          'longitude': widget.longitude,
          'address_line': (widget.addressLine != null && widget.addressLine!.isNotEmpty) 
              ? widget.addressLine 
              : (_apartmentController.text.isNotEmpty ? _apartmentController.text : "Unknown Address"),
        });
      } else {
        // Create
        final res = await AddressService.addAddress({
          'label': resolvedLabel,
          'house_floor': _houseController.text.trim(),
          'apartment_area': _apartmentController.text.trim(),
          'directions': directionsPayload,
          'latitude': widget.latitude,
          'longitude': widget.longitude,
          'address_line': (widget.addressLine != null && widget.addressLine!.isNotEmpty) 
              ? widget.addressLine 
              : (_apartmentController.text.isNotEmpty ? _apartmentController.text : "Unknown Address"),
        });
        success = res != null;
      }

      if (!success) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save address. Please try again.')),
          );
        }
        return;
      }

      // Update Location Provider
      if (mounted) {
        final fullAddress = "${_houseController.text.trim()}, ${widget.addressLine}";
         Provider.of<LocationProvider>(context, listen: false).setLocation(
           fullAddress,
           widget.latitude ?? 0,
           widget.longitude ?? 0,
           label: resolvedLabel
         );
         
         // Navigate to home (clear stack back to root)
         context.go('/');
      }

    } catch (e) {
      debugPrint('Error saving address: $e');
      if (mounted) {
        // Strip "Exception: " prefix for cleaner UI if possible
        final msg = e.toString().replaceAll("Exception: ", "");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $msg')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 1,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: AppTheme.card,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.foreground, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        title: Text(
          widget.editMode ? "Edit Address" : "Add Address Details",
          style: GoogleFonts.inter(
            color: AppTheme.foreground,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected Location Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.mapPin, color: AppTheme.foreground, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.currentLocationName ?? widget.currentLabel ?? 'Selected Location',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        Text(
                          widget.addressLine ?? '',
                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.mutedForeground),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            _buildTextField("House / Flat / Floor No.", _houseController, "Enter house/flat/floor number"),
            const SizedBox(height: 16),
            _buildTextField("Apartment / Road / Area (Recommended)", _apartmentController, "Enter apartment/road/area"),
            const SizedBox(height: 16),
            _buildTextField("Directions to Reach (Optional)", _directionsController, "e.g. Ring the bell on the red gate", maxLines: 3),
            
            if (_directionsController.text.isNotEmpty || true) // Always show hint
               Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.muted.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  "Helps us serve you better — concise directions ensure faster service.",
                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.mutedForeground),
                ),
              ),

            const SizedBox(height: 24),
            Text(
              "SAVE AS",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.mutedForeground,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPresetChip('Home', LucideIcons.home, _savedHome && !widget.editMode),
                _buildPresetChip('Work', LucideIcons.briefcase, _savedWork && !widget.editMode),
                _buildPresetChip('Friends', LucideIcons.users, false),
                _buildPresetChip('Other', LucideIcons.tag, false),
              ],
            ),

            if (_selectedPreset == 'Other') ...[
              const SizedBox(height: 16),
              _buildTextField("Save As", _customLabelController, "Enter address label"),
              const SizedBox(height: 16),
              _buildTextField("Client's phone number (optional)", _clientPhoneController, "Enter phone number", keyboardType: TextInputType.phone),
            ],

            if (_selectedPreset == 'Friends') ...[
              const SizedBox(height: 16),
              _buildTextField("Client's name", _clientNameController, "Enter client name"),
              const SizedBox(height: 16),
              _buildTextField("Client's phone number", _clientPhoneController, "Enter phone number", keyboardType: TextInputType.phone),
            ],
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _saving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        widget.editMode ? 'Update Address' : 'Save Address Details',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.mutedForeground,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: GoogleFonts.inter(color: AppTheme.foreground),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: AppTheme.mutedForeground),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String label, IconData icon, bool disabled) {
    final isSelected = _selectedPreset == label;
    return InkWell(
      onTap: disabled ? null : () => _handlePresetSelect(label),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: disabled 
              ? AppTheme.muted.withOpacity(0.3) 
              : isSelected 
                  ? AppTheme.primary.withOpacity(0.1) 
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: disabled 
                ? AppTheme.border.withOpacity(0.3) 
                : isSelected 
                    ? AppTheme.primary 
                    : AppTheme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary.withOpacity(0.2) : AppTheme.muted.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 14,
                color: disabled 
                    ? AppTheme.mutedForeground.withOpacity(0.5)
                    : isSelected 
                        ? AppTheme.primary 
                        : AppTheme.mutedForeground,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: disabled 
                    ? AppTheme.mutedForeground.withOpacity(0.5)
                    : isSelected 
                        ? AppTheme.primary 
                        : AppTheme.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
