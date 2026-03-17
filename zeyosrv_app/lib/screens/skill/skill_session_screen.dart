import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zeyosrv_app/core/theme/app_theme.dart';
import 'package:zeyosrv_app/screens/skill/widgets/booking_bottom_sheet.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zeyosrv_app/core/services/api_service.dart';
import 'package:zeyosrv_app/core/constants/api_constants.dart';
import '../profile/profile_screen.dart';

import 'package:intl/intl.dart';

class SkillSessionScreen extends StatefulWidget {
  const SkillSessionScreen({super.key});

  @override
  State<SkillSessionScreen> createState() => _SkillSessionScreenState();
}

class _SkillSessionScreenState extends State<SkillSessionScreen> {
  int _selectedIndex = 0;
  DateTime? _bookedDate;
  String? _bookedTime;
  bool _hasNotification = false;

  @override
  void initState() {
    super.initState();
    _fetchExistingBooking();
  }

import 'package:url_launcher/url_launcher.dart';
import 'package:zeyosrv_app/screens/verification/document_upload_screen.dart';

  String? _meetingLink;
  String? _status;

  Future<void> _fetchExistingBooking() async {
    try {
      final response = await ApiService.get('${ApiConstants.baseUrl}/technician/skill-session');
      
      if (response != null && response is Map<String, dynamic>) {
        setState(() {
          _meetingLink = response['meeting_link'];
          _status = response['status'];
        });

        if (response['scheduled_at'] != null) {
          final scheduledAt = DateTime.parse(response['scheduled_at']);
          final timeStr = DateFormat('h:mm a').format(scheduledAt);
          final endTime = scheduledAt.add(const Duration(hours: 1));
          final endTimeStr = DateFormat('h:mm a').format(endTime);
          
          setState(() {
            _bookedDate = scheduledAt;
            _bookedTime = "$timeStr - $endTimeStr";
          });
        }
      }
    } catch (e) {
      print('Error fetching booking: $e');
    }
  }
  
  Future<void> _launchMeeting() async {
    if (_meetingLink != null) {
      final Uri url = Uri.parse(_meetingLink!);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch meeting link')),
        );
      }
    }
  }

  Widget _buildBookedState() {
    if (_status == 'rejected') {
      return Center(
        child: Column(
          children: [
             const Icon(LucideIcons.xCircle, color: Colors.red, size: 64),
             const SizedBox(height: 16),
             Text(
               'Better luck next time',
               style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold),
             ),
             const SizedBox(height: 8),
             const Text('Your skill session was not approved this time.'),
          ],
        ),
      );
    }

    if (_status == 'approved') {
       return Center(
        child: Column(
          children: [
             const Icon(LucideIcons.checkCircle, color: Colors.green, size: 64),
             const SizedBox(height: 16),
             Text(
               'Congratulations!',
               style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold),
             ),
             const SizedBox(height: 8),
             const Text('You have passed the skill session.'),
             const SizedBox(height: 32),
             SizedBox(
               width: double.infinity,
               height: 50,
               child: ElevatedButton(
                 onPressed: () {
                   Navigator.push(
                     context,
                     MaterialPageRoute(builder: (context) => const DocumentUploadScreen()),
                   );
                 },
                 style: ElevatedButton.styleFrom(
                   backgroundColor: AppTheme.primary,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                 ),
                 child: const Text('Upload Documents', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
               ),
             ),
          ],
        ),
      );
    }

    final dateStr = DateFormat('dd MMM').format(_bookedDate!);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skill session booked',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'In this session, we will know more about your work experience',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.grey[800],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Date Row
        Row(
          children: [
            const Icon(LucideIcons.clock, size: 20),
            const SizedBox(width: 12),
            Text(
              '$dateStr, ${_bookedTime!.split('-')[0].trim()}',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Video Call Row
        Row(
          children: [
            const Icon(LucideIcons.video, size: 20),
            const SizedBox(width: 12),
             Text(
              'Video call',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 32),
        
        Row(
          children: [
            // Join Button
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _meetingLink != null ? _launchMeeting : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _meetingLink != null ? AppTheme.primary : Colors.grey[200],
                    disabledBackgroundColor: Colors.grey[200],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Join video call',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _meetingLink != null ? Colors.white : Colors.grey[500],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Change Button
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _showBookingSheet, // Reschedule
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: AppTheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Change',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

         const SizedBox(height: 40),
        const Divider(thickness: 1, color: Color(0xFFEEEEEE)),
        const SizedBox(height: 24),
        
        Text(
          'About this stage',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 24),
        
        // Info Cards (Same as unbooked)
        _buildInfoCard(
          image: 'assets/images/skill_session_1.png', 
          text: 'What is skill session?',
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          image: 'assets/images/skill_session_2.png',
          text: 'How to prepare?',
        ),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppTheme.primary : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? AppTheme.primary : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar();

  @override
  Widget build(BuildContext context) {
    // Custom Stepper/Progress bar
    return Row(
      children: [
        _buildStep('Session', true, true),
        _buildConnector(false),
        _buildStep('Starter kit', false, false),
        _buildConnector(false),
        _buildStep('Profile', false, false),
        _buildConnector(false),
        _buildStep('Training', false, false),
      ],
    );
  }

  Widget _buildStep(String label, bool isActive, bool isCompleted) {
    return Column(
      children: [
        Container(
          width: isCompleted ? 20 : 12, // Active one is larger/ring
          height: isCompleted ? 20 : 12,
          decoration: BoxDecoration(
             shape: BoxShape.circle,
             color: isActive ? Colors.black : Colors.grey[300],
             border: isCompleted 
               ? Border.all(color: Colors.black, width: 4) // Ring effect
               : null,
          ),
          child: isCompleted ? Container(
             decoration: const BoxDecoration(
               shape: BoxShape.circle,
               color: Colors.white, // Inner white
             ),
          ) : null,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.black : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? Colors.black : Colors.grey[300],
        margin: const EdgeInsets.only(bottom: 20), // Align with dots
      ),
    );
  }
}
