import 'package:flutter/material.dart';
import 'package:projectdemo/constants/settings.dart';

import '../../constants/colors.dart';

class FooterWidget extends StatelessWidget {
  final int currentPage;

  const FooterWidget({super.key, required this.currentPage});

  void _onTapp(BuildContext context, int index) {
    if (index == currentPage) return;
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, landingScreen);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, resourceScreen);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, profileScreen);
        break;
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
