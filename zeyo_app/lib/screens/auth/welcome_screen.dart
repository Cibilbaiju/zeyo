import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:math';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Navigate to home after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   IconButton(onPressed: () {}, icon: const Icon(Icons.arrow_back, color: Colors.transparent)), // spacer
                   IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz, color: Colors.black)),
                 ],
               ),
             ),
             const SizedBox(height: 60),
             Text(
              "Welcome to\nZeyo",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                height: 1.2
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Customising your experience...",
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500
              ),
            ),
            const Spacer(),
            
            
            // Success Checkmark Animation
            Center(
              child: SizedBox(
                width: 120,
                height: 120,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                     return CustomPaint(
                       painter: SuccessCheckmarkPainter(_controller.value),
                     );
                  },
                ),
              ),
            ),
            
            const Spacer(),
            const SizedBox(height: 100), // Bottom spacing
          ],
        ),
      ),
    );
  }
}

class SuccessCheckmarkPainter extends CustomPainter {
  final double progress;
  SuccessCheckmarkPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint circlePaint = Paint()
      ..color = const Color(0xFF276EF1).withOpacity(0.1 + (sin(progress * pi) * 0.1)) // Pulsing background
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw pulsing outer circle
    double radius = (size.width / 2) + (sin(progress * 2 * pi) * 4);
    canvas.drawCircle(center, radius, circlePaint);
    
    // Draw static inner circle
    final Paint innerCirclePaint = Paint()
      ..color = const Color(0xFF276EF1)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.width / 2.5, innerCirclePaint);

    // Draw Checkmark
    final checkPaint = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
      
    final Path checkPath = Path();
    checkPath.moveTo(center.dx - 15, center.dy);
    checkPath.lineTo(center.dx - 5, center.dy + 12);
    checkPath.lineTo(center.dx + 18, center.dy - 12);
    
    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant SuccessCheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
