import 'package:flutter/material.dart';
import 'screens/landing_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/networkDashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/resourceSharing_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const LandingScreen());

      case '/network':
        return MaterialPageRoute(
          builder: (_) => const NetworkDashboardScreen(),
        );


      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('404: Page not found'))),
        );
    }
  }
}
