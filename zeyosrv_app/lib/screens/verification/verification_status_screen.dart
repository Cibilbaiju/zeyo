import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:zeyosrv_app/core/constants/api_constants.dart';
import 'package:zeyosrv_app/core/theme/app_theme.dart';
import 'dart:convert';
import 'package:zeyosrv_app/screens/home/provider_dashboard_screen.dart';
import '../../core/widgets/responsive_image.dart';
import 'skill_assessment_screen.dart';
import 'video_proof_screen.dart';
import 'document_upload_screen.dart';

class VerificationStatusScreen extends StatefulWidget {
  final VoidCallback? onVerified;
  const VerificationStatusScreen({super.key, this.onVerified});

  @override
  State<VerificationStatusScreen> createState() => _VerificationStatusScreenState();
}

class _VerificationStatusScreenState extends State<VerificationStatusScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _statusData;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/verification/status'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _statusData = json.decode(response.body);
          _isLoading = false;
          
          if (_statusData?['isVerified'] == true) {
             widget.onVerified?.call();
          }
        });
      } else {
        throw Exception('Failed to load status');
      }
    } catch (e) {
        // Handle error silently or show snackbar
        if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildStepCard({
    required String title,
    required String status,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'passed':
      case 'partial': // Treat partial as completed step (provider can work on some services)
      case 'valid':
      case 'verified':
        statusColor = Colors.green;
        statusText = 'Completed';
        statusIcon = Icons.check_circle;
        break;
      case 'fail':
      case 'invalid':
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Failed/Retry';
        statusIcon = Icons.error;
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'Pending';
        statusIcon = Icons.pending;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 28),
        ),
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 16),
              const SizedBox(width: 4),
              Text(statusText, style: GoogleFonts.inter(color: statusColor, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final autoStatus = _statusData?['autoStatus'] ?? {};
    final isVerified = _statusData?['isVerified'] ?? false;

    if (isVerified) {
        return const ProviderDashboardScreen();
    }

    // Check if "Under Verification" (All steps done, but not isVerified)
    final bool allDone = (autoStatus['skill'] == 'passed' || autoStatus['skill'] == 'partial') && 
                         (autoStatus['video'] == 'valid') && 
                         (autoStatus['docs'] == 'verified');
    
    // Also check if status is specifically 'in_review' or similar if we used that
    if (allDone) {
         return Scaffold(
             body: Center(
                 child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                         const SizedBox(
                             width: 150, 
                             height: 150, 
                             child: _PulsingServiceIcon()
                         ), 
                         const SizedBox(height: 32),
                         Text('Verifying Profile...', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
                         const SizedBox(height: 16),
                         Padding(
                           padding: const EdgeInsets.symmetric(horizontal: 40),
                           child: Text(
                               'Our AI is analyzing your documents and details. This will take less than 10 minutes.', 
                               style: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
                               textAlign: TextAlign.center,
                           ),
                         ),
                         const SizedBox(height: 20),
                         ElevatedButton.icon(
                             onPressed: _fetchStatus, 
                             icon: const Icon(Icons.refresh), 
                             label: const Text("Check Status")
                         )
                     ],
                 ),
             ),
         );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Verification Status', style: GoogleFonts.inter(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
           IconButton(onPressed: _fetchStatus, icon: const Icon(Icons.refresh, color: Colors.black)) 
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Complete all steps to get verified',
            style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[700]),
          ),
          const SizedBox(height: 24),

          _buildStepCard(
            title: 'Skill Assessment',
            status: autoStatus['skill'] ?? 'pending',
            icon: Icons.quiz_outlined,
            onTap: () async {
                // Fetch my services first
                try {
                    setState(() => _isLoading = true);
                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString('auth_token');
                    final res = await http.get(
                        Uri.parse('${ApiConstants.baseUrl}/technician/services'),
                        headers: {'Authorization': 'Bearer $token'},
                    );
                    
                    setState(() => _isLoading = false);

                    if (res.statusCode == 200) {
                        final services = json.decode(res.body) as List;
                        if (services.isEmpty) {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select services first')));
                             return;
                        }

                        // Check status
                        // If all verified, show toast. If partial/pending, go to quiz.
                        // Ideally we pass the full list to the screen.
                        await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => SkillAssessmentScreen(
                                services: services, // Pass list of {id, name, is_verified}
                                status: autoStatus['skill']
                            )),
                        );
                        _fetchStatus();
                    }
                } catch (e) {
                     setState(() => _isLoading = false);
                     print(e);
                }
            },
          ),
          _buildStepCard(
            title: 'Video Proof',
            status: autoStatus['video'] ?? 'pending',
            icon: Icons.videocam_outlined,
            onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => VideoProofScreen(currentStatus: autoStatus['video'])),
                );
                _fetchStatus();
            },
          ),

          _buildStepCard(
            title: 'Document Verification',
            status: autoStatus['docs'] ?? 'pending',
            icon: Icons.description_outlined,
            onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DocumentUploadScreen(currentStatus: autoStatus['docs'])),
                );
                _fetchStatus();
            },
          ),
        ],
      ),
    );
  }
}

class _PulsingServiceIcon extends StatefulWidget {
  const _PulsingServiceIcon();

  @override
  State<_PulsingServiceIcon> createState() => _PulsingServiceIconState();
}

class _PulsingServiceIconState extends State<_PulsingServiceIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
         return Transform.scale(
            scale: _scaleAnimation.value,
            child: Stack(
              alignment: Alignment.center,
              children: [
                 Icon(Icons.circle, size: 140, color: Colors.blue.withOpacity(0.1)), // Glow
                 Icon(Icons.handyman_outlined, size: 80, color: Colors.blueAccent), // Service Icon
                 Positioned(
                   right: 30,
                   bottom: 30,
                   child: Transform.rotate(
                      angle: _controller.value * 2 * 3.14159,
                      child: const Icon(Icons.settings, size: 40, color: Colors.orange)
                   )
                 )
              ],
            ),
         );
      },
    );
  }
}
