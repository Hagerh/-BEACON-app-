import 'package:flutter/material.dart';
import 'package:projectdemo/presentation/routes/app_routes.dart';

import '../../core/constants/colors.dart';

class FooterWidget extends StatelessWidget {
  final int currentPage;

  const FooterWidget({super.key, required this.currentPage});

  void _onTapp(BuildContext context, int index) {
    if (index == currentPage) return;

    String targetRoute;
    switch (index) {
      case 0:
        targetRoute = networkDashboardScreen;
        break;
      case 1:
        targetRoute = resourceScreen;
        break;
      case 2:
        targetRoute = networkProfileScreen;
        break;
      default:
        return;
    }

    // Check if the target route already exists in the navigation stack
    final navigator = Navigator.of(context);
    bool routeExists = false;
    navigator.popUntil((route) {
      if (route.settings.name == targetRoute) {
        routeExists = true;
        return true; // Stop popping
      }
      return false; // Continue popping
    });

    if (routeExists) {
      // Route exists, just pop to it (no need to push)
      return;
    }

    // Route doesn't exist, push it without replacing
    // But first, pop back to the dashboard if we're navigating away from it
    if (currentPage == 0 && index != 0) {
      // We're leaving dashboard, push the new route
      Navigator.pushNamed(context, targetRoute);
    } else if (currentPage != 0 && index == 0) {
      // We're going back to dashboard, pop until we find it or push it
      Navigator.popUntil(context, (route) {
        if (route.settings.name == targetRoute) {
          return true;
        }
        // If we reach the first route and dashboard wasn't found, stop
        if (route.isFirst) {
          Navigator.pushNamed(context, targetRoute);
          return true;
        }
        return false;
      });
    } else {
      // Navigating between non-dashboard screens
      Navigator.pushNamed(context, targetRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE0F7FA), Color(0xFFFFE6E6)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        currentIndex: currentPage,
        selectedItemColor: AppColors.buttonPrimary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => _onTapp(context, index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.handshake_outlined),
            activeIcon: Icon(Icons.handshake),
            label: 'Resources',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}