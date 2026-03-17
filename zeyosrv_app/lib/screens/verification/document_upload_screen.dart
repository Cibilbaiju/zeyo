import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zeyosrv_app/core/theme/app_theme.dart';
import 'package:zeyosrv_app/core/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'dart:convert';
import '../../core/widgets/responsive_image.dart';

class DocumentUploadScreen extends StatefulWidget {
  final String? currentStatus;
  const DocumentUploadScreen({super.key, this.currentStatus});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final _picker = ImagePicker();
  
  XFile? _aadhaar;
  XFile? _aadhaarBack;
  XFile? _license;
  XFile? _pan;
  XFile? _photo;
  XFile? _addressProof;

  bool _isUploading = false;

  Future<void> _pickImage(String type) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                _setImage(type, image);
              },
            ),
             ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                _setImage(type, image);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _setImage(String type, XFile? image) {
    if (image != null) {
      setState(() {
        switch (type) {
          case 'aadhaar': _aadhaar = image; break;
          case 'aadhaarBack': _aadhaarBack = image; break;
          case 'license': _license = image; break;
          case 'pan': _pan = image; break;
          case 'photo': _photo = image; break;
          case 'addressProof': _addressProof = image; break;
        }
      });
    }
  }

  Future<void> _uploadDocuments() async {
    if (_aadhaar == null || _aadhaarBack == null || _license == null || _pan == null || _photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all required documents (Front & Back of Aadhaar included)')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      var request = http.MultipartRequest('POST', Uri.parse('${ApiConstants.baseUrl}/technician/upload-documents'));
      request.headers['Authorization'] = 'Bearer $token';

      if (_aadhaar != null) request.files.add(await http.MultipartFile.fromPath('aadhaar', _aadhaar!.path));
      if (_aadhaarBack != null) request.files.add(await http.MultipartFile.fromPath('aadhaarBack', _aadhaarBack!.path));
      if (_license != null) request.files.add(await http.MultipartFile.fromPath('license', _license!.path));
      if (_pan != null) request.files.add(await http.MultipartFile.fromPath('pan', _pan!.path));
      if (_photo != null) request.files.add(await http.MultipartFile.fromPath('photo', _photo!.path));
      if (_addressProof != null) request.files.add(await http.MultipartFile.fromPath('addressProof', _addressProof!.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Now trigger Verification
        final verifyRes = await http.post(
          Uri.parse('${ApiConstants.baseUrl}/verification/ocr-mock'),
          headers: {'Authorization': 'Bearer $token'},
        );
        
        // Parse result to check for waitlist/failure
        if (verifyRes.statusCode == 200) {
            final body = jsonDecode(verifyRes.body);
            if (body['success'] == false) {
                 // Moved to Waitlist or Rejected
                 if (mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(body['message'] ?? 'Verification Failed')));
                     Navigator.pop(context); // Close screen
                 }
                 return;
            }
        
            if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Documents Verified Successfully!')),
              );
              Navigator.pop(context, true); 
            }
        } else {
             throw Exception('Verification trigger failed');
        }

      } else {
        throw Exception('Upload failed: ${response.body}');
      }
    } catch (e) {
      print('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading documents: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }



  Widget _buildUploadButton(String label, XFile? file, String type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _pickImage(type),
            child: Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[50],
              ),
              child: file != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: kIsWeb 
                          ? Image.network(file.path, fit: BoxFit.cover, width: double.infinity) 
                          : Image.file(File(file.path), fit: BoxFit.cover, width: double.infinity),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_upload_outlined, color: Colors.grey),
                        const SizedBox(height: 4),
                        Text(
                          'Tap to upload',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If rejected/waitlist, allow re-upload per user request? 
    // User said: "IF ANY VULNARABILITY FOUND GIVE THE PROVIDER A OPTION TO RE UPLOAD"
    // BUT also "IF FRAUD... MOVE TO WATINGLIST".
    // Waitlist implies "Pending Manual Review" usually, but let's assume if status is 'waitlist', we show that.
    // However, if status is 'rejected', we allow re-upload (default logic). 
    
    if (widget.currentStatus == 'verified' || widget.currentStatus == 'waitlist' || widget.currentStatus == 'pending') {
         // Show read-only status
         bool isWaitlist = widget.currentStatus == 'waitlist';
         return Scaffold(
             appBar: AppBar(title: const Text('Document Verification'), backgroundColor: Colors.white, iconTheme: const IconThemeData(color: Colors.black)),
             body: Center(
                 child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                         Icon(
                            isWaitlist ? Icons.warning_amber_rounded : (widget.currentStatus == 'verified' ? Icons.verified : Icons.hourglass_top), 
                            color: isWaitlist ? Colors.orange : Colors.green, 
                            size: 80
                         ),
                         const SizedBox(height: 16),
                         Text(
                            isWaitlist ? 'Action Required' : (widget.currentStatus == 'verified' ? 'Documents Verified' : 'Documents Submitted'), 
                            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)
                         ),
                         const SizedBox(height: 8),
                         Padding(
                           padding: const EdgeInsets.symmetric(horizontal: 30),
                           child: Text(
                              isWaitlist 
                                ? 'We detected a mismatch in your documents. You have been placed on the waitlist for manual review.' 
                                : 'Your documents are under review or verified.', 
                              style: const TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                           ),
                         ),
                         if (isWaitlist) ...[
                             const SizedBox(height: 20),
                             ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Go Back"))
                         ]
                     ],
                 ),
             ),
         );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Document Verification', style: GoogleFonts.inter(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildUploadButton('Aadhaar Card (Front)', _aadhaar, 'aadhaar'),
            _buildUploadButton('Aadhaar Card (Back)', _aadhaarBack, 'aadhaarBack'),
            _buildUploadButton('Driving License', _license, 'license'),
            _buildUploadButton('PAN Card', _pan, 'pan'),
            _buildUploadButton('Profile Photo', _photo, 'photo'),
            // _buildUploadButton('Address Proof', _addressProof, 'addressProof'), // User didn't prioritize this in prompt, simplified list
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadDocuments,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isUploading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Submit Documents', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
