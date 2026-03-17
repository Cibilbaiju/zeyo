import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeyosrv_app/core/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/providers/location_provider.dart';
import '../../core/services/location_service.dart'; // Import Service
import '../../core/providers/cart_provider.dart'; // Added import
import 'widgets/typing_search_bar.dart';
import 'widgets/advertisement_carousel.dart';
import 'widgets/job_offer_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showBottomNav = true;
  double _lastScrollOffset = 0;
  double _scrollOffset = 0; // Track scroll for parallax
  StreamSubscription? _jobSubscription;
  bool _jobSheetOpen = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    
    // Listen for Job Offers
    _jobSubscription = LocationService.jobOfferStream.listen((data) {
      if (mounted) {
        _showJobOfferDialog(data);
      }
    });
  }

  Future<bool> _acceptJob(Map<String, dynamic> jobData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final technicianId = prefs.getString('tech_id');
      if (technicianId == null) {
        debugPrint('[Job Accept] No technician ID found!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login required. Technician ID missing.')),
          );
        }
        return false;
      }

      final jobId = jobData['jobId'] ?? jobData['job_id'] ?? jobData['id'];
      if (jobId == null) {
        debugPrint('[Job Accept] No job ID in data!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Job ID missing. Cannot accept.')),
          );
        }
        return false;
      }

      final response = await ApiService.post(
        '${ApiConstants.baseUrl}/jobs/accept',
        {
          'jobId': jobId,
          'technicianId': technicianId,
        },
      );

      debugPrint('[Job Accept] Response: $response');

      final success = response != null && (response['success'] == true || response['otp'] != null);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Accept failed: ${response ?? 'no response'}')),
        );
      }
      return success;
    } catch (e) {
      debugPrint('[Job Accept] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Accept error: $e')),
        );
      }
      return false;
    }
  }

  void _showJobOfferDialog(Map<String, dynamic> data) {
    if (_jobSheetOpen) return;
    _jobSheetOpen = true;
    final jobData = Map<String, dynamic>.from(data);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (ctx) => JobOfferBottomSheet(
        jobData: jobData,
        onAccept: () => _acceptJob(jobData),
        onDecline: () {
          Navigator.pop(ctx);
        },
      ),
    ).whenComplete(() {
      _jobSheetOpen = false;
    });
  }

  void _scrollListener() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });

    if (_scrollController.offset > _lastScrollOffset && _scrollController.offset > 100) {
      if (_showBottomNav) setState(() => _showBottomNav = false);
    } else {
      if (!_showBottomNav) setState(() => _showBottomNav = true);
    }
    _lastScrollOffset = _scrollController.offset;
  }

  @override
  void dispose() {
    _jobSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Animated Background with Parallax
          Positioned(
            top: -_scrollOffset * 0.5, // Parallax effect (moves at half speed)
            left: 0,
            right: 0,
            child: const AnimatedBackground(),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Header (Navigation)
                _buildHeader(context),
                
                // Sticky Search Bar
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TypingSearchBar(),
                ),

                // Scrollable Content
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: EdgeInsets.zero,
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3), // Space for background
                      
                      const SizedBox(height: 20),
                       // Greeting
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          "Explore All Services",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: AppTheme.mutedForeground,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Services Grid (Uber Style Hero)
                      _buildUberStyleHero(context),
                      
                      const SizedBox(height: 100), // Bottom padding
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Navigation
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            bottom: _showBottomNav ? 0 : -80,
            left: 0,
            right: 0,
            child: _buildBottomNavigation(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
           Expanded(
             child: GestureDetector(
               onTap: () {
                 context.push('/location-selector');
               },
               child: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   const Icon(LucideIcons.mapPin, size: 20),
                   const SizedBox(width: 8),
                   const SizedBox(width: 8),
                   Flexible(
                     child: Consumer<LocationProvider>(
                       builder: (context, locationProvider, child) {
                         return Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             Row(
                               children: [
                                 Flexible(
                                   child: Text(
                                     locationProvider.label ?? "Add address",
                                     style: GoogleFonts.inter(
                                       fontSize: 16, 
                                       fontWeight: FontWeight.bold,
                                       color: AppTheme.foreground,
                                     ),
                                     maxLines: 1,
                                     overflow: TextOverflow.ellipsis,
                                   ),
                                 ),
                                 const Icon(Icons.keyboard_arrow_down, size: 16),
                               ],
                             ),
                             if (locationProvider.address != null)
                               Text(
                                 locationProvider.address!,
                                 style: GoogleFonts.inter(
                                   fontSize: 12,
                                   color: AppTheme.mutedForeground,
                                 ),
                                 maxLines: 1,
                                 overflow: TextOverflow.ellipsis,
                               ),
                           ],
                         );
                       },
                     ),
                   ),
                 ],
               ),
             ),
           ),
            Consumer<CartProvider>(
              builder: (context, cart, child) {
                return GestureDetector(
                  onTap: () {
                    context.push('/cart');
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                         BoxShadow(
                           color: Colors.black12,
                           blurRadius: 4,
                           offset: Offset(0, 2),
                         )
                      ]
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Icon(LucideIcons.shoppingCart, size: 20, color: AppTheme.foreground),
                        ),
                        if (cart.totalItemsCount > 0)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppTheme.destructive,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                "${cart.totalItemsCount}",
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }
            ),
        ],
      ),
    );
  }

  Widget _buildUberStyleHero(BuildContext context) {
    final suggestions = [
      {
        'id': "plumber", 'title': "PLUMBING", 'subtitle': "EMERGENCY REPAIRS",
        'promo': "FLAT 25% OFF", 'image': "assets/images/service-plumber.png", 'badge': null
      },
      {
        'id': "electrician", 'title': "ELECTRICIAN", 'subtitle': "24/7 AVAILABLE",
        'promo': "UP TO ₹200 OFF", 'image': "assets/images/service-electrician.png", 'badge': null
      },
      {
        'id': "painter", 'title': "PAINTING", 'subtitle': "HOME MAKEOVER",
        'promo': "MIN ₹500 OFF", 'image': "assets/images/service-painter.png", 'badge': null
      },
      {
        'id': "tree", 'title': "TREE CUTTING", 'subtitle': "SAFE REMOVAL",
        'promo': null, 'image': "assets/images/service-tree.png", 'badge': "NEW"
      },
      {
        'id': "scanner", 'title': "SCANNING", 'subtitle': "DIGITIZATION",
        'promo': null, 'image': "assets/images/service-scanner.png", 'badge': null
      },
      {
        'id': "carpentry", 'title': "CARPENTRY", 'subtitle': "CUSTOM WORK",
        'promo': "₹300 OFF", 'image': "assets/images/service-carpentry.png", 'badge': null
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final service = suggestions[index];
              return GestureDetector(
                onTap: () {
                  if (service['id'] == 'electrician' || service['id'] == 'carpentry') {
                    context.push(
                      '/service-detail',
                      extra: {
                        'id': service['id'],
                        'title': service['title'],
                      },
                    );
                  } else {
                    context.push('/developing-stage');
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border.withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service['title'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.foreground,
                                ),
                              ),
                              Text(
                                service['subtitle'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: AppTheme.mutedForeground,
                                ),
                              ),
                              if (service['promo'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    service['promo'] as String,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: -8,
                          bottom: -8,
                          width: 80,
                          height: 80,
                          child: Image.asset(
                            service['image'] as String,
                            fit: BoxFit.contain,
                          ),
                        ),
                        if (service['badge'] != null)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.destructive,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                service['badge'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: (index * 100).ms);
            },
          ),
          
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.primaryForeground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Book a Service Now"),
                  SizedBox(width: 8),
                  Icon(LucideIcons.arrowRight, size: 16),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          // Advertisement Carousel
          const AdvertisementCarousel(),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: const Border(top: BorderSide(color: AppTheme.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(null, "Home", true, isLogo: true),
              _buildNavItem(LucideIcons.calendar, "Bookings", false),
              _buildNavItem(LucideIcons.messageCircle, "Chat", false),
              _buildNavItem(LucideIcons.user, "Account", false, onTap: () => context.push('/profile')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData? icon, String label, bool isActive, {bool isLogo = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLogo)
             Image.asset('assets/images/scanning-logo.png', width: 24, height: 24)
          else
             Icon(
               icon,
               size: 24,
               color: isActive ? AppTheme.foreground : AppTheme.mutedForeground,
             ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isActive ? AppTheme.foreground : AppTheme.mutedForeground,
            ),
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 16,
              height: 2,
              decoration: BoxDecoration(
                color: AppTheme.foreground,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
        ],
      ),
    );
  }
}

class AnimatedBackground extends StatelessWidget {
  const AnimatedBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.52,
      child: Stack(
        children: [
          Positioned(
            top: -MediaQuery.of(context).size.height * 0.05,
            left: 0,
            right: 0,
            bottom: 0,
            child: Lottie.asset(
              'assets/images/home.json',
              fit: BoxFit.cover,
            ),
          ),
          // Gradient overlays (simplified for Flutter)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 50,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.background.withOpacity(0),
                    AppTheme.background,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
