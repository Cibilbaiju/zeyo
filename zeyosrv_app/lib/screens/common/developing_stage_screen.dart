import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zeyosrv_app/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class DevelopingStageScreen extends StatelessWidget {
  const DevelopingStageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.foreground),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Crane/Construction Icon
            const Icon(
              LucideIcons.construction,
              size: 80,
              color: AppTheme.primary,
            )
            .animate(onPlay: (controller) => controller.repeat())
            .rotate(begin: -0.1, end: 0.1, duration: 2000.ms, curve: Curves.easeInOut)
            .then()
            .rotate(begin: 0.1, end: -0.1, duration: 2000.ms, curve: Curves.easeInOut),
            
            const SizedBox(height: 24),
            
            Text(
              "Developing Stage",
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.foreground,
              ),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 8),
            
            Text(
              "We're currently working on this feature.\nStay tuned for updates!",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.mutedForeground,
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
          ],
        ),
      ),
    );
  }
}
