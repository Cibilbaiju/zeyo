import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zeyosrv_app/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class SearchingServiceScreen extends StatefulWidget {
  final String serviceName;

  const SearchingServiceScreen({
    super.key,
    required this.serviceName,
  });

  @override
  State<SearchingServiceScreen> createState() => _SearchingServiceScreenState();
}

class _SearchingServiceScreenState extends State<SearchingServiceScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    // Simulate finding a service after a delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
         // Determine next step based on logic, for now just go back or to a success page
         // This is a placeholder for actual finding logic
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Technicians found for ${widget.serviceName}!")),
         );
         context.pop(); 
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
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ScaleTransition(
                  scale: Tween(begin: 0.8, end: 1.2).animate(
                    CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
                  ),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary.withOpacity(0.1),
                    ),
                  ),
                ),
                ScaleTransition(
                  scale: Tween(begin: 1.0, end: 1.5).animate(
                    CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
                  ),
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary.withOpacity(0.2),
                    ),
                  ),
                ),
                Container(
                   width: 100,
                   height: 100,
                   decoration: BoxDecoration(
                     color: Colors.white,
                     shape: BoxShape.circle,
                     boxShadow: [
                       BoxShadow(
                         color: Colors.black.withOpacity(0.1),
                         blurRadius: 10,
                         offset: const Offset(0, 4),
                       )
                     ]
                   ),
                   child: const Icon(Icons.search, size: 40, color: AppTheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              "Searching for...",
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppTheme.mutedForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.serviceName,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.foreground,
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "We are looking for the best technicians near you. Please wait a moment.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  color: AppTheme.mutedForeground,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => context.pop(),
              child: Text(
                "Cancel Search",
                style: GoogleFonts.inter(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
