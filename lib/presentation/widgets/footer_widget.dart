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

    // For dashboard navigation, try to pop back to existing route
    if (index == 0) {
      // Check if dashboard route exists in stack
      bool found = false;
      Navigator.popUntil(context, (route) {
        if (route.settings.name == targetRoute) {
          found = true;
          return true; // Stop popping, found the route
        }
        // Don't pop past the first route
        if (route.isFirst) {
          return true; // Stop popping
        }
        return false; // Continue popping
      });

      // If dashboard wasn't found, we can't navigate to it without networkName
      // This shouldn't happen in normal flow, but handle gracefully
      if (!found) {
        // Try to get networkName from current route arguments if available
        final currentRoute = ModalRoute.of(context);
        final currentArgs = currentRoute?.settings.arguments;
        String? networkName;

        if (currentArgs is Map<String, dynamic>) {
          networkName = currentArgs['networkName']?.toString();
        }

        // If we have networkName, push new dashboard route
        if (networkName != null) {
          Navigator.pushNamed(
            context,
            targetRoute,
            arguments: {'networkName': networkName},
          );
        }
        // If no networkName, can't navigate - this is an error state
      }
    } else {
      // For non-dashboard routes, just push them
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
