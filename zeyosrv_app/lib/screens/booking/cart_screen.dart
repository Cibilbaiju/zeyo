import 'package:flutter/material.dart';
import 'package:zeyosrv_app/core/providers/cart_provider.dart';
import 'package:zeyosrv_app/core/providers/user_provider.dart';
import 'package:zeyosrv_app/core/providers/location_provider.dart';
import 'package:zeyosrv_app/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:zeyosrv_app/core/services/address_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _addressConfirmed = false;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      appBar: AppBar(
        title: Text(
          "Your cart",
          style: GoogleFonts.inter(
            color: AppTheme.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.foreground),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.shoppingCart, size: 64, color: AppTheme.mutedForeground),
                  const SizedBox(height: 16),
                  Text(
                    "Hey, it feels so empty here.",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Lets add some services",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () => context.go('/'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E2E2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      "Explore services", 
                      style: GoogleFonts.inter(
                        color: const Color(0xFF000000),
                        fontWeight: FontWeight.w600,
                        fontSize: 14
                      )
                    ),
                  )
                ],
              ),
            );
          }

          // Calculate dynamic totals
          double itemTotal = 0;
          double totalSavings = 0;
          
          cart.items.forEach((key, item) {
             final originalPrice = item.originalPrice ?? item.price;
             itemTotal += originalPrice * item.quantity;
             totalSavings += (originalPrice - item.price) * item.quantity;
          });
          
          double taxes = 9; // Keep fixed for now
          double totalToPay = cart.totalAmount + taxes;

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Savings Banner
                if (totalSavings > 0)
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.local_offer, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Saving ₹${totalSavings.toStringAsFixed(0)} on this order",
                          style: GoogleFonts.inter(
                            color: Colors.green[800],
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Cart Items
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                         final cartItem = cart.items.values.toList()[index];
                         return Padding(
                           padding: const EdgeInsets.symmetric(vertical: 12),
                           child: Row(
                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                             children: [
                               Expanded(
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text(
                                       cartItem.title,
                                       style: GoogleFonts.inter(
                                         fontWeight: FontWeight.w500,
                                         fontSize: 16,
                                         color: AppTheme.foreground,
                                       ),
                                     ),
                                   ],
                                 ),
                               ),
                               Row(
                                 children: [
                                   // Quantity Control
                                   Container(
                                     decoration: BoxDecoration(
                                       border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                                       borderRadius: BorderRadius.circular(6),
                                       color: AppTheme.primary.withOpacity(0.05),
                                     ),
                                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                     child: Row(
                                       children: [
                                         InkWell(
                                           onTap: () => cart.removeSingleItem(cartItem.id),
                                           child: const Icon(Icons.remove, size: 16, color: AppTheme.primary),
                                         ),
                                         const SizedBox(width: 12),
                                         Text(
                                           "${cartItem.quantity}",
                                           style: GoogleFonts.inter(
                                             color: AppTheme.primary,
                                             fontWeight: FontWeight.bold,
                                           ),
                                         ),
                                         const SizedBox(width: 12),
                                          InkWell(
                                             onTap: () => cart.addItem(cartItem.id, cartItem.price, cartItem.title, cartItem.image, cartItem.category, cartItem.originalPrice),
                                             child: const Icon(Icons.add, size: 16, color: AppTheme.primary),
                                          ),
                                       ],
                                     ),
                                   ),
                                   const SizedBox(width: 16),
                                   Column(
                                     crossAxisAlignment: CrossAxisAlignment.end,
                                     children: [
                                       if (cartItem.originalPrice != null && cartItem.originalPrice! > cartItem.price)
                                        Text(
                                          "₹${(cartItem.originalPrice! * cartItem.quantity).toStringAsFixed(0)}",
                                          style: GoogleFonts.inter(
                                            decoration: TextDecoration.lineThrough,
                                            color: AppTheme.mutedForeground,
                                            fontSize: 12,
                                          ),
                                        ),
                                       Text(
                                          "₹${(cartItem.price * cartItem.quantity).toStringAsFixed(0)}",
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: AppTheme.foreground,
                                          ),
                                       ),
                                     ],
                                   )
                                 ],
                               )
                             ],
                           ),
                         );
                    },
                  ),
                ),
                const SizedBox(height: 8),

                // Coupons
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.percent, color: Colors.green), // Or a specific icon
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Coupons and offers",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: AppTheme.foreground,
                              ),
                            ),
                            Text(
                              user != null ? "6 offers" : "Login/Sign up to view offers",
                              style: GoogleFonts.inter(
                                color: user != null ? AppTheme.primary : AppTheme.mutedForeground,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppTheme.primary),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                const SizedBox(height: 8),

                // Payment Summary
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Payment summary",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppTheme.foreground,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Item Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Item total", style: GoogleFonts.inter(color: AppTheme.mutedForeground)),
                          Text(
                            "₹${itemTotal.toStringAsFixed(0)}", 
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600, 
                                color: AppTheme.foreground
                            )
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Discount
                      if (totalSavings > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Item discount", style: GoogleFonts.inter(color: AppTheme.mutedForeground)),
                          Text(
                            "-₹${totalSavings.toStringAsFixed(0)}", 
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600, 
                                color: Colors.green
                            )
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Taxes and Fee", style: GoogleFonts.inter(color: AppTheme.mutedForeground)),
                          Text(
                            "₹${taxes.toStringAsFixed(0)}", 
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600, 
                                color: AppTheme.foreground
                            )
                          ),
                        ],
                      ),
                      const Padding(
                         padding: EdgeInsets.symmetric(vertical: 12),
                         child: Divider(),
                      ),
                      // Total Amount (Technically redundant with Amount to pay, but following pattern)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           Text(
                             "Total amount", 
                             style: GoogleFonts.inter(
                               fontWeight: FontWeight.bold, 
                               fontSize: 16
                             )
                           ),
                           Text(
                             "₹${totalToPay.toStringAsFixed(0)}", 
                              style: GoogleFonts.inter(
                               fontWeight: FontWeight.bold, 
                               fontSize: 16
                             )
                           ),
                        ],
                      ),
                      const Padding(
                         padding: EdgeInsets.symmetric(vertical: 12),
                         child: Divider(),
                      ),
                       Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           Text(
                             "Amount to pay", 
                             style: GoogleFonts.inter(
                               fontWeight: FontWeight.bold, 
                               fontSize: 16
                             )
                           ),
                           Text(
                             "₹${totalToPay.toStringAsFixed(0)}", 
                              style: GoogleFonts.inter(
                               fontWeight: FontWeight.bold, 
                               fontSize: 16
                             )
                           ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomSheet: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) return const SizedBox.shrink();
          
          return Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Address Section
                Consumer<LocationProvider>(
                  builder: (context, location, _) {
                    final address = location.address;
                    final label = location.label ?? "Home";
                    
                    if (address == null || !_addressConfirmed) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () => _showAddressSelection(context),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.mapPin, size: 20, color: AppTheme.foreground),
                            const SizedBox(width: 12),
                            Expanded(
                              child: RichText(
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "$label - ",
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.foreground,
                                        fontSize: 14,
                                      ),
                                    ),
                                    TextSpan(
                                      text: address,
                                      style: GoogleFonts.inter(
                                        color: AppTheme.foreground,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Text(
                               "Change",
                               style: GoogleFonts.inter(
                                 color: AppTheme.primary,
                                 fontWeight: FontWeight.w600,
                                 fontSize: 14
                               ),
                            )
                          ],
                        ),
                      ),
                    );
                  }
                ),

                SizedBox(
                   width: double.infinity,
                   child: ElevatedButton(
                     onPressed: () {
                        if (user == null) {
                          context.push('/auth');
                          return;
                        }
                        
                        if (cart.items.isEmpty) return;

                        // Check address
                        final location = Provider.of<LocationProvider>(context, listen: false);
                        if (location.address == null || !_addressConfirmed) {
                           _showAddressSelection(context);
                           return;
                        }
                        
                        // Determine service name for display
                        String serviceName = "Service";
                        final items = cart.items.values.toList();
                        if (items.isNotEmpty) {
                           final categories = items.map((e) => e.category).toSet();
                           if (categories.length > 1) {
                             serviceName = "Experts";
                           } else {
                             String cat = categories.first;
                             if (cat.toLowerCase() == "carpentry") serviceName = "Carpenter";
                             else if (cat.toLowerCase() == "plumbing") serviceName = "Plumber";
                             else if (cat.toLowerCase() == "electrecian") serviceName = "Electrician";
                             else if (cat.toLowerCase() == "painting") serviceName = "Painter";
                             else serviceName = cat;
                             
                             serviceName = serviceName.split(' ').map((e) => e[0].toUpperCase() + e.substring(1)).join(' ');
                           }
                        }

                        context.push('/searching-service', extra: {'serviceName': serviceName});
                     },
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.black, // Changed to black
                       padding: const EdgeInsets.symmetric(vertical: 16),
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(8),
                       ),
                     ),
                      child: !_addressConfirmed 
                        ? Text(
                            "Select Address",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            user != null 
                               ? (cart.items.values.isNotEmpty 
                                    ? _getButtonText(cart.items.values.toList())
                                    : "Select slots")
                               : "Login to place order",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                    ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getButtonText(List<CartItem> items) {
    if (items.isEmpty) return "Select slots";
    
    // Get all unique categories
    final categories = items.map((e) => e.category).toSet();
    
    if (categories.length > 1) {
      return "Book Services";
    }
    
    final category = categories.first;
    // Handle specific mappings if needed, or just use the category name
    // e.g. "Electrician" -> "Book Electrician", "Carpentry" -> "Book Carpenter"
    // For now, let's try to be smart about titles
    String title = category;
    if (category.toLowerCase() == "carpentry") title = "Carpenter";
    if (category.toLowerCase() == "plumbing") title = "Plumber";
    if (category.toLowerCase() == "electrecian") title = "Electrecian";
    if (category.toLowerCase() == "tree cutting") title = "Tree cutter";
    if (category.toLowerCase() == "painting") title = "Painter";

   // Title Case
    title = title.toLowerCase().split(' ').map((e) => e[0].toUpperCase() + e.substring(1)).join(' ');
    
    return "Book $title";
  }

  Future<List<Map<String, dynamic>>> _fetchSavedAddresses() async {
    final addresses = await AddressService.getAddresses();
    return addresses.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  void _showAddressSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
             Padding(
               padding: const EdgeInsets.all(16),
               child: Text("Select Address", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
             ),
             const Divider(height: 1),
             ListTile(
               leading: const Icon(LucideIcons.plus, color: AppTheme.primary),
               title: Text("Add new address", style: GoogleFonts.inter(color: AppTheme.primary, fontWeight: FontWeight.w600)),
               onTap: () {
                 context.pop();
                 context.push('/location-selector');
               },
             ),
             const Divider(height: 1),
             Expanded(
               child: FutureBuilder<List<Map<String, dynamic>>>(
                 future: _fetchSavedAddresses(),
                 builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("No saved addresses", style: GoogleFonts.inter(color: Colors.grey)),
                            const SizedBox(height: 8),
                            Text("Click 'Add new address' above", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                          ],
                        )
                      );
                    }
                    
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final addr = snapshot.data![index];
                        return ListTile(
                          leading: Icon(
                            (addr['label'] as String?)?.toLowerCase() == 'home' ? LucideIcons.home : 
                            (addr['label'] as String?)?.toLowerCase() == 'work' ? LucideIcons.briefcase : LucideIcons.mapPin,
                            color: Colors.black87
                          ),
                          title: Text(addr['label'] ?? 'Address', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          subtitle: Text(addr['address_line'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                          onTap: () {
                             Provider.of<LocationProvider>(context, listen: false).setLocation(
                               addr['address_line'] ?? '',
                               (addr['latitude'] as num).toDouble(),
                               (addr['longitude'] as num).toDouble(),
                               label: addr['label']
                             );
                             setState(() {
                               _addressConfirmed = true;
                             });
                             context.pop();
                          },
                        );
                      }
                    );
                 }
               ),
             )
          ],
        ),
      )
    );
  }
}
