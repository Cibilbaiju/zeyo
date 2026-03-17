import 'package:flutter/material.dart';
import 'dart:async';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  late AnimationController _lineController;
  late Animation<double> _lineAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Logo Pulse Animation (Breathe effect)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // 2s cycle
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 2. Line Loading Animation (Uber style indeterminate)
    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Animate from left (-30% width) to right (100% width)
    _lineAnimation = Tween<double>(begin: -0.3, end: 1.0).animate(
      CurvedAnimation(parent: _lineController, curve: Curves.easeInOut),
    );

    // 3. Navigation Timer
    Timer(const Duration(seconds: 4), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _lineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Uber Black
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Image
            // Ensure you add 'assets/logo.png' to your pubspec.yaml
            FadeTransition(
              opacity: _pulseAnimation, 
              child: Image.asset(
                'assets/logo.png', // Replace with your actual asset path
                width: 200, // Matching the demo Scale
                color: Colors.white, // Invert black logo to white
              ),
            ),
            const SizedBox(height: 30),
            
            // Loader Line
            SizedBox(
              width: 200, // Same width as logo roughly
              height: 2,
              child: Stack(
                children: [
                  // Background Track
                  Container(
                    color: Colors.white.withOpacity(0.2),
                  ),
                  // Moving Highlight
                  AnimatedBuilder(
                    animation: _lineAnimation,
                    builder: (context, child) {
                      return FractionallySizedBox(
                        widthFactor: 0.3, // 30% width highlight
                        alignment: Alignment(_lineAnimation.value * 2 - 1, 0), // Map 0..1 to -1..1 alignment
                        child: Container(
                          color: Colors.white,
                        ),
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
}

