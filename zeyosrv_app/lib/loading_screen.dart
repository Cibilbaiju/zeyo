import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zeyosrv_app/screens/home/home_screen.dart';

class LoadingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const LoadingScreen({Key? key, required this.onComplete}) : super(key: key);

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with TickerProviderStateMixin {
  // 1. Entrance Controller (Logo Slide+Fade, Line Fade)
  late AnimationController _entranceController;
  late Animation<double> _logoFadeAnimation;
  late Animation<Offset> _logoSlideAnimation;
  late Animation<double> _lineFadeAnimation;

  // 2. Pulse Controller (Logo Breathing)
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // 3. Line Movement Controller (The "Indeterminate" Uber line)
  late AnimationController _lineController;
  late Animation<double> _lineMoveAnimation;

  @override
  void initState() {
    super.initState();

    // --- ENTRANCE ANIMATIONS ---
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100), // Covers 0.8s logo + 0.3s delay
    );

    // CSS: animation: fadeIn 0.8s ease-out forwards;
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.72, curve: Curves.easeOut), // 0.8s / 1.1s ≈ 0.72
      ),
    );

    // CSS: transform: translateY(10px) -> translateY(0);
    _logoSlideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.72, curve: Curves.easeOut),
      ),
    );

    // CSS: .loader-line animation: fadeIn 0.8s ease-out 0.3s forwards;
    // Starts at 0.3s, ends at 0.3+0.8=1.1s
    _lineFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.27, 1.0, curve: Curves.easeOut), // 0.3s / 1.1s ≈ 0.27
      ),
    );

    // --- PULSE ANIMATION ---
    // CSS: animation: ... textPulse 2s ease-in-out 0.8s infinite;
    // Starts after entrance (0.8s).
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Trigger Pulse after entrance
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _pulseController.repeat(reverse: true);
    });

    // --- LINE MOVEMENT ANIMATION ---
    // CSS: animation: lineAnim 1.5s cubic-bezier(0.4, 0, 0.2, 1) infinite;
    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _lineMoveAnimation = CurvedAnimation(
      parent: _lineController,
      curve: const Cubic(0.4, 0, 0.2, 1),
    );

    // Start Entrance
    _entranceController.forward();

    // --- NAVIGATION ---
    // CSS: 3.5s simulation
    // --- NAVIGATION ---
    // CSS: 3.5s simulation
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        _checkLocationPermission();
      }
    });
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) _showBlockingDialog();
        return;
      }
    }
    
    // Permission granted
    widget.onComplete();
  }

  void _showBlockingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Location Required'),
        content: const Text('Zeyo Partner requires location access to match you with nearby jobs. Please enable location in settings.'),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await Geolocator.openAppSettings();
              // After returning from settings, user might need to restart or we re-check?
              // For simplicity, we just close dialog and re-check manually or let them restart app.
              // Better UX: Wait a bit or add a "Retry" button. 
              // Proceeding to close dialog for retry.
              Navigator.pop(ctx);
              _checkLocationPermission();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    _lineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // CSS: background-color: #000000;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // LOGO
            // CSS: .logo-img { width: 250px; margin: 0 0 30px 0; }
            SlideTransition(
              position: _logoSlideAnimation,
              child: FadeTransition(
                opacity: _logoFadeAnimation,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _pulseController.isAnimating ? _pulseAnimation.value : 1.0,
                      child: child,
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 30),
                    child: Text(
                      'Zeyo Srv',
                      style: GoogleFonts.inter(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // LOADER LINE
            // CSS: .loader-line { width: 100%; height: 2px; ... .container { width: 200px } }
            // So logical width is 200px.
            FadeTransition(
              opacity: _lineFadeAnimation,
              child: Container(
                width: 200,
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2), // rgba(255,255,255,0.2)
                  borderRadius: BorderRadius.circular(2),
                ),
                clipBehavior: Clip.antiAlias,
                child: AnimatedBuilder(
                  animation: _lineMoveAnimation,
                  builder: (context, child) {
                    final t = _lineMoveAnimation.value;
                    
                    // Logic from CSS @keyframes lineAnim:
                    // 0%: left: 0, width: 0%
                    // 50%: width: 30%
                    // 100%: left: 100%, width: 0%
                    
                    // Interpolate left (alignment) from -1 (0%) to 1 (100%)
                    // Note: In CSS 'left' moves the element.
                    // We can use Fractional offset.
                    
                    // Let's model "left" as linear 0->100% relative to container?
                    // The CSS says: 0% { left: 0 } ... 100% { left: 100% }.
                    // This implies the element's left edge moves from 0 to 100%.
                    final double alignmentX = -1.0 + (t * 2.0); // Map 0..1 to -1..1
                    
                    // Interpolate width:
                    // 0 -> 0.5: width 0 -> 30%
                    // 0.5 -> 1.0: width 30% -> 0%
                    double widthFactor;
                    if (t <= 0.5) {
                      widthFactor = (t / 0.5) * 0.3;
                    } else {
                      widthFactor = ((1.0 - t) / 0.5) * 0.3;
                    }

                    return Align(
                      alignment: Alignment(alignmentX, 0),
                      child: FractionallySizedBox(
                        widthFactor: widthFactor,
                        heightFactor: 1.0,
                        child: Container(color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
