import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:zeyosrv_app/core/constants/api_constants.dart';
import 'package:zeyosrv_app/core/theme/app_theme.dart';
import 'dart:convert';

class VideoProofScreen extends StatefulWidget {
  final String? currentStatus;
  const VideoProofScreen({super.key, this.currentStatus});

  @override
  State<VideoProofScreen> createState() => _VideoProofScreenState();
}

class _VideoProofScreenState extends State<VideoProofScreen> {
  XFile? _videoFile; // Use XFile for cross-platform
  final _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickVideo() async {
    showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
              child: Wrap(
                children: [
                  ListTile(
                    leading: const Icon(Icons.videocam),
                    title: const Text('Record Video'),
                    onTap: () async {
                      Navigator.pop(context);
                      final XFile? video = await _picker.pickVideo(
                        source: ImageSource.camera,
                        maxDuration: const Duration(minutes: 1),
                      );
                      if (video != null) setState(() => _videoFile = video);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.video_library),
                    title: const Text('Choose from Gallery'),
                    onTap: () async {
                      Navigator.pop(context);
                      final XFile? video = await _picker.pickVideo(
                        source: ImageSource.gallery,
                        maxDuration: const Duration(minutes: 1),
                      );
                      if (video != null) setState(() => _videoFile = video);
                    },
                  ),
                ],
              ),
            ));
  }

  Future<void> _uploadVideo() async {
    if (_videoFile == null) return;
    setState(() => _isUploading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // Note: On Web, we can't easily upload 'File' object path.
      // We would use readAsBytes(), checking kIsWeb.
      // Since this is a MOCK upload (sending URL string), we just simulate it.
      
      await Future.delayed(const Duration(seconds: 2));
      final mockUrl = 'https://example.com/videos/mock_video_${DateTime.now().millisecondsSinceEpoch}.mp4';

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/verification/video-proof'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'videoUrl': mockUrl,
          'duration': 45,
        }),
      );

      final result = json.decode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Video uploaded successfully!')),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception(result['error'] ?? 'Upload failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentStatus == 'valid' || widget.currentStatus == 'pending') {
         return Scaffold(
             appBar: AppBar(title: const Text('Video Proof'), backgroundColor: Colors.white, iconTheme: const IconThemeData(color: Colors.black)),
             body: Center(
                 child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                         Icon(widget.currentStatus == 'valid' ? Icons.check_circle : Icons.hourglass_top, color: Colors.green, size: 80),
                         const SizedBox(height: 16),
                         Text(widget.currentStatus == 'valid' ? 'Video Verified' : 'Video Submitted', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
                         const SizedBox(height: 8),
                         const Text('You have already submitted your video proof.', style: TextStyle(color: Colors.grey)),
                     ],
                 ),
             ),
         );
    }
  
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Proof', style: GoogleFonts.inter(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload a short video (30-45s) demonstrating your skills or introducing yourself.',
              style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 30),
            
            InkWell(
              onTap: _pickVideo,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[50],
                ),
                child: _videoFile != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 50),
                          const SizedBox(height: 10),
                          Text('Video Selected', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                          Text(_videoFile!.name, style: GoogleFonts.inter(fontSize: 12)), // Use .name for XFile
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.videocam_outlined, color: Colors.grey, size: 60),
                          const SizedBox(height: 10),
                          Text('Tap to record or select video', style: GoogleFonts.inter(color: Colors.grey)),
                        ],
                      ),
              ),
            ),
            
            const Spacer(),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_videoFile == null || _isUploading) ? null : _uploadVideo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Upload Video', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


