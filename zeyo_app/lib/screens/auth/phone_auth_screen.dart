import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // Removing Supabase
// import '../../core/services/supabase_service.dart'; // Removing Supabase
import '../../core/services/auth_service_backend.dart'; // Adding Backend Service
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/constants/countries.dart';
import '../../core/services/socket_service.dart'; // Import SocketService

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

enum AuthStep { phone, otp }

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController(); 
  final FocusNode _otpFocusNode = FocusNode();
  
  AuthStep _step = AuthStep.phone;
  bool _loading = false;
  Map<String, String> _selectedCountry = {'code': '+91', 'name': 'India', 'flag': '🇮🇳', 'iso': 'IN'};
  
  // Saved account from local storage
  Map<String, String>? _foundAccount;

  // Countries list
  List<Map<String, String>> _countries = [];

  @override
  void initState() {
    super.initState();
    _countries = List.from(allCountries);
    _countries.sort((a, b) => a['name']!.compareTo(b['name']!));
    _fetchUserCountry();
    _loadSavedAccount();
  }

  Future<void> _fetchUserCountry() async {
    try {
      final response = await http.get(Uri.parse('http://ip-api.com/json'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final countryCode = data['countryCode'] as String?; // e.g., 'IN'
        
        if (countryCode != null && mounted) {
           final country = _countries.firstWhere(
             (c) => c['iso'] == countryCode,
             orElse: () => {},
           );
           
           if (country.isNotEmpty) {
             setState(() {
               _selectedCountry = country;
             });
           }
        }
      }
    } catch (e) {
      debugPrint('Error fetching country: $e');
    }
  }

  Future<void> _loadSavedAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPhone = prefs.getString('last_login_phone');
    if (lastPhone != null && mounted) {
      setState(() {
        _foundAccount = {
          'name': 'Welcome Back', // Generic welcome as we only saved phone
          'phone': lastPhone,
          'email': '', // Not saved yet
          'avatar': '', // Placeholder or empty
        };
      });
    }
  }

  Timer? _timer;
  int _secondsRemaining = 30;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _otpFocusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _secondsRemaining = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _timer?.cancel();
          }
        });
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleSendOtp({String? phoneNumber}) async {
    final phone = phoneNumber ?? _phoneController.text.trim();
    if (phone.length < 8) {
      _showError('Please enter a valid phone number');
      return;
    }

    setState(() => _loading = true);
    FocusScope.of(context).unfocus();

    try {
      // Send raw digits for test number to match config
      final isTestNumber = phone == '8289876643';
      final fullPhone = phoneNumber ?? (isTestNumber ? phone : '${_selectedCountry['code']}$phone');
      
      print('Attempting login with: $fullPhone');  

      // Call Backend API
      await AuthServiceBackend.sendOtp(fullPhone);
      
      print('OTP sent successfully');

      if (mounted) {
        setState(() {
          _step = AuthStep.otp;
          _loading = false;
        });
        _startTimer();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) FocusScope.of(context).requestFocus(_otpFocusNode);
        });
      }
    } catch (error) {
       print('Error: $error');
       if (mounted) setState(() => _loading = false);
       _showError('Failed to send OTP: $error');
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showError('Please enter the 6-digit OTP');
      return;
    }

    setState(() => _loading = true);

    try {
      final rawPhone = _phoneController.text.trim();
      final isTestNumber = rawPhone == '8289876643';

      String phoneToVerify = isTestNumber ? rawPhone : '${_selectedCountry['code']}$rawPhone';
      
      if (_phoneController.text.isEmpty) {
        phoneToVerify = '+918089485895';
      }

      // Verify via Backend API
      final result = await AuthServiceBackend.verifyOtp(phoneToVerify, otp);

      // Initialize Socket
      await SocketService.initSocket();
      
      print('Login Success: $result');
      
      // Save login on success
      if (mounted) {
         final prefs = await SharedPreferences.getInstance();
         await prefs.setString('last_login_phone', phoneToVerify);
         
         if (mounted) {
             Provider.of<UserProvider>(context, listen: false).loginSuccess();
             context.go('/welcome');
         }
      }
    } catch (error) {
      if (mounted) setState(() => _loading = false);
      _showError('Verification failed: $error');
    }
  }
  
  void _showFindAccountSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Is this you?",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            if (_foundAccount != null)
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey[200],
                    child: const Icon(LucideIcons.user, color: Colors.black),
                    // backgroundImage: _foundAccount!['avatar']!.isNotEmpty ? NetworkImage(_foundAccount!['avatar']!) : null,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _foundAccount!['name']!,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _foundAccount!['phone']!,
                        style: GoogleFonts.inter(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 32),
             SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                   Navigator.pop(context); 
                   if (_foundAccount != null) {
                      // Parse stored phone to separate code and number if needed, 
                      // or just parse logic to fill controller
                      // For simplicity, let's just trigger send OTP with the stored full phone
                      _handleSendOtp(phoneNumber: _foundAccount!['phone']); 
                   }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  "Yes, It's me",
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
             SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "No, this is not me",
                  style: GoogleFonts.inter(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
             children: [
               const SizedBox(height: 12),
               Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
               Expanded(
                 child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: _countries.length,
                    itemBuilder: (context, index) {
                      final c = _countries[index];
                      final isSelected = c['iso'] == _selectedCountry['iso'];
                      return Container(
                        color: isSelected ? Colors.grey[100] : null,
                        child: ListTile(
                          leading: Text(c['flag']!, style: const TextStyle(fontSize: 24)),
                          title: Text(c['name']!, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                          trailing: Text(c['code']!, style: GoogleFonts.inter(color: Colors.black)),
                          onTap: () {
                            setState(() => _selectedCountry = c);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
               ),
             ],
          ),
        );
      },
    );
  }

  Widget _buildPhoneInput() {
    return Row(
      children: [
        // Country Selector
        GestureDetector(
          onTap: _showCountryPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                 Text(
                   _selectedCountry['flag']!,
                   style: const TextStyle(fontSize: 24),
                 ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_drop_down, size: 18, color: Colors.black),
              ],
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Phone Field
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    autofocus: true,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      prefixText: "${_selectedCountry['code']} ",
                      prefixStyle: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 16),
                      hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const Icon(LucideIcons.user, size: 20, color: Colors.black),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // Only show back button if we are in OTP step or want to navigate back to "Get Started"
        leading: _step == AuthStep.otp 
           ? IconButton(
               icon: const Icon(Icons.arrow_back, color: Colors.black),
               onPressed: () => setState(() => _step = AuthStep.phone),
             )
           : IconButton(
               icon: const Icon(Icons.arrow_back, color: Colors.black),
               onPressed: () => context.go('/get-started'),
             ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               // Title
               Text(
                 _step == AuthStep.phone 
                   ? 'Enter your mobile number' 
                   : 'Enter the 6-digit code sent via\nSMS at ${_selectedCountry['code']} ${_phoneController.text.isNotEmpty ? _phoneController.text : "..."}.', 
                 style: GoogleFonts.inter(
                   fontSize: 20,
                   fontWeight: FontWeight.w500, 
                   color: Colors.black,
                 ),
               ),
               
               if (_step == AuthStep.otp)
                 Padding(
                   padding: const EdgeInsets.only(top: 8),
                   child: GestureDetector(
                     onTap: () => setState(() => _step = AuthStep.phone),
                     child: Text(
                       "Changed your mobile number?",
                       style: GoogleFonts.inter(
                         decoration: TextDecoration.underline,
                         color: Colors.black,
                         fontSize: 14
                       ),
                     ),
                   ),
                 ),
               
               const SizedBox(height: 24),
               
               if (_step == AuthStep.phone) ...[
                 _buildPhoneInput(),
                 const SizedBox(height: 16),
                 SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _handleSendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Continue", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                 ),
                 
                 const SizedBox(height: 24),
                 _buildDivider("or"),
                 const SizedBox(height: 24),
                 
                 _buildSocialButton(Icons.apple, "Continue with Apple"),
                 const SizedBox(height: 12),
                 _buildSocialButton(LucideIcons.chrome, "Continue with Google"), 
                 const SizedBox(height: 12),
                 _buildSocialButton(LucideIcons.mail, "Continue with Email"),
                 
                  if (_foundAccount != null) ...[
                 const SizedBox(height: 24),
                 _buildDivider("or"),
                 const SizedBox(height: 24),
                 
                 InkWell(
                   onTap: _showFindAccountSheet,
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       const Icon(LucideIcons.search, size: 20),
                       const SizedBox(width: 8),
                       Text(
                         "Find my account", 
                         style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
                       ),
                     ],
                   ),
                 ),
                  ],
                 
                 const Spacer(),
                 Text(
                   "By continuing, you agree to calls, including by autodialer, WhatsApp, or texts from zeyo and its affiliates.", 
                   textAlign: TextAlign.center,
                   style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12),
                 ),
                 const SizedBox(height: 16),
    
               ] else ...[
                 _buildOtpInput(),
                 const SizedBox(height: 24),
                 
                 GestureDetector(
                   onTap: () {
                     _otpController.clear();
                     _handleSendOtp();
                   },
                   child: Container(
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                     decoration: BoxDecoration(
                       color: Colors.grey[200],
                       borderRadius: BorderRadius.circular(20),
                     ),
                     child: Text(
                       "Resend code via SMS",
                       style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                     ),
                   ),
                 ),
                 
                 const Spacer(),
                 
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     InkWell(
                       onTap: () => setState(() => _step = AuthStep.phone),
                       child: Container(
                         padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
                         child: const Icon(Icons.arrow_back),
                       ),
                     ),
                     InkWell(
                       onTap: _handleVerifyOtp,
                       child: Container(
                         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                         decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(24)),
                         child: Row(
                           children: [
                             Text("Next", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.grey[500])),
                             const SizedBox(width: 8),
                             Icon(Icons.arrow_forward, size: 18, color: Colors.grey[500]),
                           ],
                         ),
                       ),
                     ),
                   ],
                 ),
                 const SizedBox(height: 24),
               ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDivider(String text) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[300])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(text, style: GoogleFonts.inter(color: Colors.grey[500])),
        ),
        Expanded(child: Divider(color: Colors.grey[300])),
      ],
    );
  }
  
  Widget _buildSocialButton(IconData icon, String text) {
     return Container(
       width: double.infinity,
       height: 50,
       decoration: BoxDecoration(
         color: const Color(0xFFE8E8E8), 
         borderRadius: BorderRadius.circular(8),
       ),
       child: Stack(
         children: [
           Align(
             alignment: Alignment.centerLeft,
             child: Padding(
               padding: const EdgeInsets.only(left: 16),
               child: Icon(icon, size: 24, color: Colors.black),
             ),
           ),
           Align( 
             alignment: Alignment.center,
             child: Text(text, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
           ),
         ],
       ),
     );
  }
  


  Widget _buildOtpInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                 final text = _otpController.text;
                 final char = index < text.length ? text[index] : '';
                 final isFocused = _otpFocusNode.hasFocus && index == text.length;
                 
                 return Container(
                   width: 52,
                   height: 52,
                   alignment: Alignment.center,
                   decoration: BoxDecoration(
                     color: Colors.white,
                     border: Border.all(
                       color: isFocused ? Colors.black : Colors.grey[300]!,
                       width: isFocused ? 2 : 1,
                     ),
                     borderRadius: BorderRadius.circular(12),
                   ),
                   child: Text(
                     char,
                     style: GoogleFonts.inter(
                       fontSize: 22,
                       fontWeight: FontWeight.w600,
                       color: Colors.black,
                     ),
                   ),
                 );
              }),
            ),
            
            Positioned.fill(
              child: TextField(
                controller: _otpController,
                focusNode: _otpFocusNode,
                keyboardType: TextInputType.number,
                maxLength: 6,
                showCursor: false,
                enableInteractiveSelection: false,
                cursorColor: Colors.transparent,
                style: const TextStyle(color: Colors.transparent),
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  fillColor: Colors.transparent,
                  filled: false,
                ),
                onChanged: (val) {
                  setState(() {});
                  if (val.length == 6) {
                    _handleVerifyOtp();
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
