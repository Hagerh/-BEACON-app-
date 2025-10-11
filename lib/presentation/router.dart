import 'package:flutter/material.dart';
import 'package:projectdemo/constants/settings.dart';
import 'package:projectdemo/presentation/screens/profile_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/networkDashboard_screen.dart';

class AppRouter {
  static Route? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case landingScreen:
        return MaterialPageRoute(builder: (_) => const LandingScreen());

      case networkScreen:
        return MaterialPageRoute(
          builder: (_) => const NetworkDashboardScreen(),
        );

      case profileScreen:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('404: Page not found'))),
        );
    }
  }
}
