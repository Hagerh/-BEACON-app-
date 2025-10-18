import 'package:flutter/material.dart';

import '../../constants/colors.dart';


class BeaconLogo extends StatelessWidget {
  final double width;
  final double height;
  final bool isPortrait;

  const BeaconLogo({super.key, required this.width, required this.height, required this.isPortrait});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,

      children: [
        //const SizedBox(height:20),
        Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.wifi_tethering, size: 50, color: AppColors.connectionTeal),
            Icon(Icons.circle, size: 20, color: AppColors.alertRed),
          ],
        ),

        Text(
          "BEACON",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        Text(
          "Stay Connected. Stay Safe.",
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
