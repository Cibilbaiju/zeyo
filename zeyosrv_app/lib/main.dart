import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zeyosrv_app/core/providers/user_provider.dart';
import 'package:zeyosrv_app/core/providers/location_provider.dart';
import 'package:zeyosrv_app/core/providers/cart_provider.dart';

import 'package:zeyosrv_app/core/theme/app_theme.dart';
import 'package:zeyosrv_app/screens/auth/phone_auth_screen.dart';
import 'package:zeyosrv_app/screens/auth/get_started_screen.dart';
import 'package:zeyosrv_app/screens/auth/welcome_screen.dart';
import 'package:zeyosrv_app/loading_screen.dart';
import 'package:zeyosrv_app/screens/home/home_screen.dart';
import 'package:zeyosrv_app/screens/location/location_selector_screen.dart';
import 'package:zeyosrv_app/screens/profile/profile_screen.dart';
import 'package:zeyosrv_app/screens/location/location_map_screen.dart';
import 'package:zeyosrv_app/screens/location/address_details_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:zeyosrv_app/screens/home/service_detail_screen.dart';
import 'package:zeyosrv_app/screens/booking/cart_screen.dart';
import 'package:zeyosrv_app/screens/common/developing_stage_screen.dart';
import 'package:zeyosrv_app/screens/booking/searching_service_screen.dart';
import 'package:zeyosrv_app/screens/skill/skill_session_screen.dart';
import 'package:zeyosrv_app/screens/auth/service_selection_screen.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  try {
    // print("Initializing Supabase...");
    // await SupabaseService.initialize();
    // print("Supabase initialized successfully.");
  } catch (e) {
    print("Supabase initialization failed: $e");
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late GoRouter _router;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    _router = GoRouter(
      initialLocation: '/splash', // Start at splash
      refreshListenable: userProvider,
      redirect: (context, state) {
        final loggedIn = userProvider.isLoggedIn;
        final isLoading = userProvider.isLoading;
        
        // If still loading User state, allow splash
        if (isLoading) return null;

        final isSplash = state.uri.toString() == '/splash';
        if (isSplash) {
          // Stay on splash until it manually navigates, 
          // OR we could force navigation here if we wanted no animation.
          // For now, let LoadingScreen handle navigation onComplete.
          return null; 
        }

        final isAuthRoute = state.uri.toString() == '/auth' || state.uri.toString() == '/get-started';
        
        // Protected Routes Protection
        if (!loggedIn && !isAuthRoute && state.uri.toString() != '/welcome') {
           // Provide safe fallbacks
           return '/auth'; 
        }
        
        // If logged in and trying to access Auth/GetStarted, go home
        if (loggedIn && isAuthRoute) {
          return '/skill-session';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => LoadingScreen(
            onComplete: () {
               final user = Provider.of<UserProvider>(context, listen: false);
               if (user.isLoggedIn) {
                 context.go('/skill-session');
               } else {
                 context.go('/auth');
               }
            },
          ),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/get-started',
          builder: (context, state) => const GetStartedScreen(),
        ),
        GoRoute(
          path: '/welcome',
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/auth',
          builder: (context, state) => const PhoneAuthScreen(),
        ),
        GoRoute(
          path: '/location-selector',
          builder: (context, state) => const LocationSelectorScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/location-map',
          builder: (context, state) => const LocationMapScreen(),
        ),
        GoRoute(
          path: '/address-details',
          builder: (context, state) {
             final extra = state.extra as Map<String, dynamic>? ?? {};
             return AddressDetailsScreen(
               latitude: extra['latitude'] as double?,
               longitude: extra['longitude'] as double?,
               addressLine: extra['address'] as String? ?? extra['address_line'] as String?,
               editMode: extra['editMode'] as bool? ?? false,
               addressId: extra['addressId'] as String?,
               currentLabel: extra['currentLabel'] as String?,
               currentHouseFloor: extra['currentHouseFloor'] as String?,
               currentApartmentArea: extra['currentApartmentArea'] as String?,
               currentDirections: extra['currentDirections'] as String?,
             );
          },
        ),
        GoRoute(
          path: '/service-detail',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return ServiceDetailScreen(
              serviceId: extra['id'] ?? '',
              serviceTitle: extra['title'] ?? 'Service',
            );
          },
        ),
        GoRoute(
          path: '/cart',
          builder: (context, state) => const CartScreen(),
        ),
        GoRoute(
          path: '/developing-stage',
          builder: (context, state) => const DevelopingStageScreen(),
        ),
        GoRoute(
          path: '/searching-service',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return SearchingServiceScreen(
              serviceName: extra?['serviceName'] ?? 'Service',
            );
          },
        ),
        GoRoute(
          path: '/skill-session',
          builder: (context, state) => const SkillSessionScreen(),
        ),
        GoRoute(
          path: '/service-selection',
          builder: (context, state) => const ServiceSelectionScreen(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Zeyo',
      theme: AppTheme.theme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
