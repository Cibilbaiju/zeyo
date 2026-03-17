import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_app/core/providers/user_provider.dart';
import 'package:flutter_app/core/providers/location_provider.dart';
import 'package:flutter_app/core/providers/cart_provider.dart';

import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/screens/auth/phone_auth_screen.dart';
import 'package:flutter_app/screens/auth/get_started_screen.dart';
import 'package:flutter_app/screens/auth/welcome_screen.dart';
import 'package:flutter_app/loading_screen.dart';
import 'package:flutter_app/screens/home/home_screen.dart';
import 'package:flutter_app/screens/location/location_selector_screen.dart';
import 'package:flutter_app/screens/profile/profile_screen.dart';
import 'package:flutter_app/screens/location/location_map_screen.dart';
import 'package:flutter_app/screens/location/address_details_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/screens/home/service_detail_screen.dart';
import 'package:flutter_app/screens/booking/cart_screen.dart';
import 'package:flutter_app/screens/common/developing_stage_screen.dart';
import 'package:flutter_app/screens/booking/searching_service_screen.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  
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
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    // If showSplash is true, we show the LoadingScreen.
    // However, since MultiProvider is now above MyApp, 
    // we can access providers even here if needed (though not strictly required for LoadingScreen).
    
    if (_showSplash) {
      return MaterialApp(
        title: 'Zeyo',
        theme: AppTheme.theme,
        home: LoadingScreen(
          onComplete: () {
            setState(() {
              _showSplash = false;
            });
          },
        ),
      );
    }

    return const AppContent();
  }
}

class AppContent extends StatefulWidget {
  const AppContent({super.key});

  @override
  State<AppContent> createState() => _AppContentState();
}

class _AppContentState extends State<AppContent> {
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    _router = GoRouter(
      initialLocation: '/',
      refreshListenable: userProvider,
      redirect: (context, state) {
        final loggedIn = userProvider.isLoggedIn;
        final isAuthRoute = state.uri.toString() == '/auth';
        
        if (userProvider.isLoading) return null;

        if (!loggedIn && !isAuthRoute) {
           // Allow access to get-started
           if (state.uri.toString() == '/get-started') return null;
           return '/get-started';
        }
        
        if (loggedIn && (isAuthRoute || state.uri.toString() == '/get-started')) return '/';

        return null;
      },
      routes: [
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
              serviceId: extra?['serviceId'] ?? '',
              jobId: extra?['jobId']?.toString(),
              paymentMethod: extra?['paymentMethod'],
              serviceDetails: extra?['serviceDetails'],
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    if (userProvider.isLoading) {
      return const MaterialApp(
        home: Scaffold(
          backgroundColor: AppTheme.background,
          body: Center(
              child: CircularProgressIndicator(color: AppTheme.primary)),
        ),
      );
    }

    // Should not happen if initState works, but safe guard
    if (_router == null) { 
        return const SizedBox.shrink(); 
    }

    return MaterialApp.router(
      title: 'Zeyo',
      theme: AppTheme.theme,
      routerConfig: _router!,
    );
  }
}
