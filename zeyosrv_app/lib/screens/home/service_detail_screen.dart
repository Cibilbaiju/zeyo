import 'package:zeyosrv_app/core/providers/cart_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:zeyosrv_app/core/theme/app_theme.dart';

class ServiceDetailScreen extends StatefulWidget {
  final String serviceId;
  final String serviceTitle;

  const ServiceDetailScreen({
    super.key,
    required this.serviceId,
    required this.serviceTitle,
  });

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  // Data structure for different services
  final Map<String, Map<String, dynamic>> _serviceData = {
    'carpentry': {
      'categories': [
        {'id': '1', 'title': 'Cupboard & drawer', 'icon': 'assets/images/cat_cupboard.png'},
        {'id': '2', 'title': 'Kitchen fittings', 'icon': 'assets/images/cat_kitchen.png'},
        {'id': '3', 'title': 'Shelves & decor', 'icon': 'assets/images/cat_shelves.png'},
        {'id': '4', 'title': 'Bath fittings & mirrors', 'icon': 'assets/images/cat_bath.png'},
        {'id': '5', 'title': 'Wooden door', 'icon': 'assets/images/cat_door.png'},
        {'id': '6', 'title': 'Window & curtain', 'icon': 'assets/images/cat_window.png'},
      ],
      'services': [
        {
          'id': '1',
          'title': 'Cupboard repair',
          'rating': 4.77,
          'reviews': '46K',
          'price': 89,
          'image': 'assets/images/service_cupboard.png',
          'description': 'Repairing of hinges, handles, locks, channels & more',
          'options': 5,
        },
        {
          'id': '2',
          'title': 'Cupboard lock & latches',
          'rating': 4.72,
          'reviews': '17K',
          'price': 79,
          'image': 'assets/images/service_lock.png',
          'description': 'Installation or replacement of locks',
          'options': 3,
        },
        {
          'id': '3',
          'title': 'Drawer repair & installation',
          'rating': 4.76,
          'reviews': '16K',
          'price': 89,
          'image': 'assets/images/service_drawer.png',
          'description': 'Fixing stuck drawers, channel replacement',
          'options': 4,
        },
         {
          'id': '4',
          'title': 'Pull out drawer repair/replacement',
          'rating': 4.75,
          'reviews': '28K',
          'price': 129,
          'image': 'assets/images/service_kitchen.png',
          'description': 'Smooth functioning of kitchen drawers',
          'options': 0,
        },
      ],
      'headerImage': 'assets/images/service-carpentry.png',
      'defaultCategory': 'Cupboard & drawer'
    },
    'electrician': {
      'categories': [
        {'id': 'e1', 'title': 'Switch & Socket', 'icon': 'assets/images/cat_switch.png'},
        {'id': 'e2', 'title': 'Fan', 'icon': 'assets/images/cat_fan.png'},
        {'id': 'e3', 'title': 'Light', 'icon': 'assets/images/cat_light.png'},
        {'id': 'e4', 'title': 'MCB & Fuse', 'icon': 'assets/images/cat_mcb.png'},
        {'id': 'e5', 'title': 'Inverter & Stabilizer', 'icon': 'assets/images/cat_inverter.png'},
        {'id': 'e6', 'title': 'Appliance', 'icon': 'assets/images/cat_appliance.png'},
      ],
      'services': [
        {
          'id': 'e_s1',
          'title': 'Switch/Socket replacement',
          'rating': 4.81,
          'reviews': '52K',
          'price': 49,
          'image': 'assets/images/service_switch.png',
          'description': 'Replacement of non-functional switch or socket',
          'options': 2,
          'variants': [
             {'title': 'Regular switch', 'price': 69, 'reviews': '68K', 'rating': 4.82, 'image': 'assets/images/cat_switch.png'},
             {'title': 'Power switch (16 AMP)', 'price': 89, 'reviews': '22K', 'rating': 4.82, 'image': 'assets/images/cat_switch.png'},
             {'title': 'Power socket (16 AMP)', 'price': 129, 'reviews': '15K', 'rating': 4.83, 'image': 'assets/images/cat_switch.png'},
          ],
          'steps': [
             {'title': 'Inspection', 'desc': 'We inspect your switch/socket & share a repair quote for approval'},
             {'title': 'Quote approval', 'desc': 'You can approve the quote to proceed, or pay a visitation charge if declined'},
             {'title': 'Repair & spare parts', 'desc': 'If needed, we will source spare parts from the local market'},
             {'title': 'Replacement, if needed', 'desc': 'If repair is not possible, we will replace the switch/socket'},
             {'title': 'Warranty activation', 'desc': 'The service is covered by a 30-day warranty for any issues after repair'},
          ],
          'exclusions': [
             'Wiring beyond 2 meters is not included. Extra charges apply.',
          ],
          'technicians': true,
        },
        {
          'id': 'e_s2',
          'title': 'Fan repair',
          'rating': 4.75,
          'reviews': '35K',
          'price': 119,
          'image': 'assets/images/cat_fan.png',
          'description': 'Repair of ceiling, wall or pedestal fans',
          'options': 3,
        },
        {
          'id': 'e_s3',
          'title': 'Light installation/repair',
          'rating': 4.79,
          'reviews': '22K',
          'price': 99,
          'image': 'assets/images/service_light.png',
          'description': 'Installation of wall lights, tube lights, or fancy lights',
          'options': 4,
        },
        {
          'id': 'e_s4',
          'title': 'MCB fuse replacement',
          'rating': 4.85,
          'reviews': '12K',
          'price': 149,
          'image': 'assets/images/cat_mcb.png',
          'description': 'Replacement of fused MCB or fuse',
          'options': 0,
        },
      ],
      'headerImage': 'assets/images/service-electrician.png',
      'defaultCategory': 'Switch & Socket'
    }
  };

  late String _selectedCategory;
  late List<Map<String, dynamic>> _currentCategories;
  late List<Map<String, dynamic>> _currentServices;
  String? _currentHeaderImage;

  @override
  void initState() {
    super.initState();
    _loadServiceData();
  }

  void _loadServiceData() {
    final data = _serviceData[widget.serviceId] ?? _serviceData['carpentry']!;
    _currentCategories = data['categories'] as List<Map<String, dynamic>>;
    _currentServices = data['services'] as List<Map<String, dynamic>>;
    _currentHeaderImage = data['headerImage'] as String?;
    _selectedCategory = data['defaultCategory'] as String;
  }

  void _showCategoryMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
             boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "All Categories",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.foreground,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _currentCategories.length,
                  itemBuilder: (context, index) {
                    final cat = _currentCategories[index];
                    final isSelected = cat['title'] == _selectedCategory;
                    return GestureDetector(
                      onTap: () {
                         setState(() {
                           _selectedCategory = cat['title'];
                         });
                         Navigator.pop(context);
                      },
                      child: Column(
                        children: [
                          Container(
                            height: 70,
                            width: 70,
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primary.withOpacity(0.1) : AppTheme.muted.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected ? Border.all(color: AppTheme.primary, width: 2) : null,
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Image.asset(
                              cat['icon'],
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => 
                                Icon(
                                  LucideIcons.grid, 
                                  size: 28, 
                                  color: isSelected ? AppTheme.primary : AppTheme.foreground
                                ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cat['title'],
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppTheme.primary : AppTheme.foreground,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showServiceDetailSheet(BuildContext context, Map<String, dynamic> service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Stack(
                children: [
                  ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: 20),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 40), // For close button
                            Text(
                              service['title'],
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.foreground,
                              ),
                            ),
                             const SizedBox(height: 4),
                             Row(
                               children: [
                                 const Icon(Icons.star, size: 14, color: AppTheme.foreground),
                                 const SizedBox(width: 4),
                                 Text(
                                   "${service['rating']} (${service['reviews']} reviews)",
                                   style: GoogleFonts.inter(
                                     fontSize: 14,
                                     color: AppTheme.mutedForeground,
                                   ),
                                 ),
                               ],
                             ),
                             const SizedBox(height: 16),
                             const Divider(),
                          ],
                        ),
                      ),
                      
                      // Variants
                      if (service['variants'] != null) ...[
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: (service['variants'] as List).length,
                            itemBuilder: (context, index) {
                              final variant = (service['variants'] as List)[index];
                              return Container(
                                width: 150,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Center(
                                        child: Image.asset(
                                            variant['image'],
                                            height: 80,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_,__,___) => const Icon(Icons.electrical_services, size: 40),
                                        )
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      variant['title'],
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                     Row(
                                       children: [
                                         const Icon(Icons.star, size: 10, color: AppTheme.foreground),
                                         const SizedBox(width: 2),
                                         Text(
                                           "${variant['rating']} (${variant['reviews']})",
                                           style: GoogleFonts.inter(
                                             fontSize: 10,
                                             color: AppTheme.mutedForeground,
                                           ),
                                         ),
                                       ],
                                     ),
                                     const SizedBox(height: 8),
                                     Row(
                                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                       children: [
                                          Text(
                                           "₹${variant['price']}",
                                           style: GoogleFonts.inter(
                                             fontWeight: FontWeight.bold,
                                           ),
                                          ),
                                          TextButton(
                                            onPressed: (){}, 
                                            style: TextButton.styleFrom(
                                              side: const BorderSide(color: AppTheme.border),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                            ),
                                            child: const Text("Add"),
                                          )
                                       ]
                                     )
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(thickness: 4, color: AppTheme.muted),
                        const SizedBox(height: 16),
                      ],
                      
                      // Process Steps
                      if (service['steps'] != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            "Our process",
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: (service['steps'] as List).length,
                          itemBuilder: (context, index) {
                            final step = (service['steps'] as List)[index];
                            final isLast = index == (service['steps'] as List).length - 1;
                            
                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: AppTheme.muted,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            "${index + 1}",
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (!isLast)
                                        Expanded(
                                          child: Container(
                                            width: 1,
                                            color: AppTheme.border,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 24.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            step['title'],
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            step['desc'],
                                            style: GoogleFonts.inter(
                                              color: AppTheme.mutedForeground,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const Divider(thickness: 4, color: AppTheme.muted),
                        const SizedBox(height: 16),
                      ],
                      
                      // Exclusions
                      if (service['exclusions'] != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            "What is excluded?",
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...((service['exclusions'] as List).map((e) => 
                           Padding(
                             padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                             child: Row(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 const Icon(Icons.close, color: Colors.red, size: 20),
                                 const SizedBox(width: 12),
                                 Expanded(
                                   child: Text(
                                     e,
                                     style: GoogleFonts.inter(fontSize: 14, color: AppTheme.mutedForeground),
                                   ),
                                 ),
                               ],
                             ),
                           )
                        )).toList(),
                        const SizedBox(height: 16),
                        const Divider(thickness: 4, color: AppTheme.muted),
                        const SizedBox(height: 16),
                      ],
                      
                      // Top Technicians
                      if (service['technicians'] == true) ...[
                         Padding(
                           padding: const EdgeInsets.symmetric(horizontal: 16),
                           child: Row(
                             children: [
                               Expanded(
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text(
                                       "Top technicians",
                                       style: GoogleFonts.inter(
                                         fontSize: 18,
                                         fontWeight: FontWeight.bold,
                                       ),
                                     ),
                                     const SizedBox(height: 16),
                                     _buildTechFeature(Icons.verified_user_outlined, "Background verified"),
                                     _buildTechFeature(Icons.build_outlined, "Trained across all major brands"),
                                     _buildTechFeature(Icons.stars_outlined, "Certified under Skill India Programme"),
                                   ],
                                 ),
                               ),
                               const SizedBox(width: 16),
                               // Placeholder for Technician Image
                               Container(
                                 width: 100,
                                 height: 100,
                                 decoration: BoxDecoration(
                                    color: Colors.amber[100],
                                    shape: BoxShape.circle,
                                    image: const DecorationImage(
                                      image: AssetImage('assets/images/service_switch.png'), // Use existing image as placeholder
                                      fit: BoxFit.cover,
                                    )
                                 ),
                               )
                             ],
                           ),
                         ),
                         const SizedBox(height: 16),
                         const Divider(thickness: 4, color: AppTheme.muted),
                         const SizedBox(height: 16),
                      ],
                      
                      // Zeyo Cover Promise
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Color(0xFF008955)),
                                  const SizedBox(width: 4),
                                  Text(
                                    "zeyocover",
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF008955),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "promise",
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.foreground
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildPromiseItem(Icons.verified_outlined, "Up to 30 days of warranty"),
                              _buildPromiseItem(Icons.umbrella_outlined, "Up to ₹10,000 damage cover"),
                          ],
                        ),
                      ),
                      
                    ],
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        shadowColor: Colors.black26,
                        elevation: 4,
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildTechFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.foreground),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPromiseItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.foreground),
          const SizedBox(width: 12),
          Text(text, style: GoogleFonts.inter(fontSize: 14, color: AppTheme.foreground)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.background,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.foreground),
                onPressed: () => context.pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search, color: AppTheme.foreground),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: AppTheme.foreground),
                  onPressed: () {},
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: const Color(0xFFFFE0CC), // Light orange/peach background
                    ),
                    if (_currentHeaderImage != null)
                      Positioned(
                         right: 0,
                         top: 0,
                         bottom: 0,
                         width: MediaQuery.of(context).size.width * 0.45,
                         child: Image.asset(
                           _currentHeaderImage!,
                           fit: BoxFit.cover,
                           errorBuilder: (ctx, err, stack) => Container(color: Colors.grey[300]),
                         ),
                      ),
                    Positioned(
                      left: 20,
                      bottom: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF008955), // Green color
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "Super saver",
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: Text(
                              "Affordable repairs starting at just ₹49",
                              style: GoogleFonts.inter(
                                color: AppTheme.foreground,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 4, 
                            width: 100, 
                            color: Colors.white.withOpacity(0.5),
                            child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: 40, 
                                  color: Colors.white
                                )
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.serviceTitle,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.foreground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: AppTheme.foreground),
                        const SizedBox(width: 4),
                        Text(
                          "4.76 (1.7 M bookings)",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppTheme.mutedForeground,
                            decoration: TextDecoration.underline,
                            decorationStyle: TextDecorationStyle.dotted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      
              // Offers Horizontal Scroll
              SizedBox(
                height: 60,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildOfferCard(
                      "Get visitation fee off",
                      "On orders above ₹499",
                      Icons.local_offer,
                      Colors.green
                    ),
                    const SizedBox(width: 12),
                    _buildOfferCard(
                      "Up to ₹150 cashback",
                      "Via Paytm UPI on orders...",
                      Icons.account_balance_wallet,
                      Colors.blue
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              const Divider(height: 1, color: AppTheme.border),
              const SizedBox(height: 16),

              // Sub Categories Grid (Preview)
               Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _currentCategories.length > 6 ? 6 : _currentCategories.length,
                  itemBuilder: (context, index) {
                    final cat = _currentCategories[index];
                    return GestureDetector(
                      onTap: () {
                         setState(() {
                           _selectedCategory = cat['title'];
                         });
                      },
                      child: Column(
                        children: [
                          Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              color: AppTheme.muted.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Image.asset(
                              cat['icon'],
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => 
                                 Icon(
                                  LucideIcons.grid, 
                                  size: 32, 
                                  color: AppTheme.foreground
                                ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cat['title'],
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.foreground,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),
              
              // Sticky Header for Section 
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  _selectedCategory,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.foreground,
                  ),
                ),
              ),
              
              // Service Items List
              Consumer<CartProvider>(
                builder: (context, cart, child) {
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _currentServices.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final service = _currentServices[index];
                      final qty = cart.getQuantity(service['id']);
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppTheme.border)),
                        ),
                        child: GestureDetector(
                          onTap: () => _showServiceDetailSheet(context, service),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               Expanded(
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text(
                                       service['title'],
                                       style: GoogleFonts.inter(
                                         fontSize: 16,
                                         fontWeight: FontWeight.w600,
                                         color: AppTheme.foreground,
                                       ),
                                     ),
                                     const SizedBox(height: 4),
                                     Row(
                                       children: [
                                         const Icon(Icons.star, size: 12, color: AppTheme.foreground),
                                         const SizedBox(width: 4),
                                         Text(
                                           "${service['rating']} (${service['reviews']} reviews)",
                                           style: GoogleFonts.inter(
                                             fontSize: 12,
                                             color: AppTheme.mutedForeground,
                                             decoration: TextDecoration.underline,
                                           ),
                                         ),
                                       ],
                                     ),
                                     const SizedBox(height: 8),
                                     Text(
                                       "Starts at ₹${service['price']}",
                                       style: GoogleFonts.inter(
                                         fontSize: 14,
                                         fontWeight: FontWeight.bold,
                                         color: AppTheme.foreground,
                                       ),
                                     ),
                                     const SizedBox(height: 8),
                                     GestureDetector(
                                       onTap: () => _showServiceDetailSheet(context, service),
                                       child: Text(
                                         "View details",
                                         style: GoogleFonts.inter(
                                           fontSize: 14,
                                           color: AppTheme.primary,
                                           fontWeight: FontWeight.w500,
                                         ),
                                       ),
                                     ),
                                   ],
                                 ),
                               ),
                               const SizedBox(width: 16),
                               // Image and Add Button
                               SizedBox(
                                 width: 100,
                                 height: 112, // 100 image + 12 overhang
                                 child: Stack(
                                   children: [
                                     Positioned(
                                       top: 0,
                                       left: 0,
                                       right: 0,
                                       height: 100,
                                       child: Container(
                                         decoration: BoxDecoration(
                                           borderRadius: BorderRadius.circular(8),
                                           color: AppTheme.muted,
                                           image: DecorationImage(
                                               image: AssetImage(service['image'] as String), 
                                               fit: BoxFit.cover,
                                               onError: (exception, stackTrace) {},
                                           )
                                         ),
                                         child: (service['image'] as String).isEmpty 
                                            ? const Icon(Icons.image_not_supported) 
                                            : null,
                                       ),
                                     ),
                                     Positioned(
                                       bottom: 0,
                                       left: 10,
                                       right: 10,
                                       height: 32,
                                       child: Container(
                                         decoration: BoxDecoration(
                                           color: Colors.white,
                                           borderRadius: BorderRadius.circular(6),
                                           boxShadow: [
                                             BoxShadow(
                                               color: Colors.black.withOpacity(0.1),
                                               blurRadius: 4,
                                               offset: const Offset(0, 2),
                                             ),
                                           ],
                                           border: Border.all(color: AppTheme.border.withOpacity(0.5)),
                                         ),
                                         child: qty == 0 
                                         ? TextButton(
                                           onPressed: () {
                                              cart.addItem(
                                                service['id'], 
                                                (service['price'] as num).toDouble(), 
                                                service['title'], 
                                                service['image'],
                                                widget.serviceTitle, // Pass category
                                                (service['originalPrice'] as num?)?.toDouble()
                                              );
                                           },
                                           style: TextButton.styleFrom(
                                             padding: EdgeInsets.zero,
                                             minimumSize: Size.zero,
                                           ),
                                           child: Text(
                                             "Add",
                                             style: GoogleFonts.inter(
                                               color: AppTheme.primary,
                                               fontWeight: FontWeight.bold,
                                               fontSize: 14,
                                             ),
                                           ),
                                         )
                                         : Row(
                                           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                           children: [
                                             InkWell(
                                               onTap: () => cart.removeSingleItem(service['id']),
                                               child: const Icon(Icons.remove, size: 16, color: AppTheme.primary),
                                             ),
                                             Text(
                                               "$qty", 
                                               style: GoogleFonts.inter(
                                                  color: AppTheme.primary,
                                                  fontWeight: FontWeight.bold,
                                               )
                                             ),
                                             InkWell(
                                               onTap: () {
                                                  cart.addItem(
                                                    service['id'], 
                                                    (service['price'] as num).toDouble(), 
                                                    service['title'], 
                                                    service['image'],
                                                    widget.serviceTitle, // Pass category
                                                    (service['originalPrice'] as num?)?.toDouble()
                                                  );
                                               },
                                               child: const Icon(Icons.add, size: 16, color: AppTheme.primary),
                                             ),
                                           ],
                                         ),
                                       ),
                                     ),
                                   ],
                                 ),
                               ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              ),
              
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: Consumer<CartProvider>(
        builder: (context, cart, child) {
           if (cart.totalItemsCount == 0) {
             // Generic Menu button if no items
             return GestureDetector(
               onTap: _showCategoryMenu,
               child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.grid_view_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Menu",
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
             );
           }
           
           // View Cart Bar
           return Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16),
             child: InkWell(
               onTap: () => context.push('/cart'),
               child: Container(
                 width: double.infinity,
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                 decoration: BoxDecoration(
                   color: AppTheme.primary,
                   borderRadius: BorderRadius.circular(12),
                   boxShadow: const [
                     BoxShadow(
                       color: Colors.black26, 
                       blurRadius: 10,
                       offset: Offset(0, 4)
                     )
                   ]
                 ),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Row(
                       children: [
                         Container(
                           padding: const EdgeInsets.all(6),
                           decoration: BoxDecoration(
                             border: Border.all(color: Colors.white),
                             borderRadius: BorderRadius.circular(4),
                           ),
                           child: Text(
                             "${cart.totalItemsCount}",
                             style: GoogleFonts.inter(
                               color: Colors.white,
                               fontWeight: FontWeight.bold,
                               fontSize: 12
                             ),
                           ),
                         ),
                         const SizedBox(width: 12),
                         Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           mainAxisSize: MainAxisSize.min,
                           children: [
                               Text(
                                 "₹${cart.totalAmount.toStringAsFixed(0)}",
                                 style: GoogleFonts.inter(
                                   color: Colors.white,
                                   fontWeight: FontWeight.bold,
                                   fontSize: 14
                                 ),
                               ),
                               Text(
                                 "plus taxes",
                                 style: GoogleFonts.inter(
                                   color: Colors.white.withOpacity(0.8),
                                   fontSize: 10
                                 ),
                               ),
                           ],
                         )
                       ],
                     ),
                     Row(
                       children: [
                         Text(
                           "View cart",
                           style: GoogleFonts.inter(
                             color: Colors.white,
                             fontWeight: FontWeight.w600,
                             fontSize: 14,
                           ),
                         ),
                         const SizedBox(width: 8),
                         const Icon(Icons.arrow_right, color: Colors.white), 
                       ],
                     )
                   ],
                 ),
               ),
             ),
           );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildOfferCard(String title, String subtitle, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.foreground,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppTheme.mutedForeground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
