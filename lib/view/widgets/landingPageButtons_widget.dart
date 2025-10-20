import 'package:flutter/material.dart';

class LandingpagebuttonsWidget extends StatelessWidget {
  final IconData icon;
  final String text;
  final double width;
  final double height;
  final bool isPortrait;

  const LandingpagebuttonsWidget({super.key, required this.icon, required this.text, required this.width, required this.height, required this.isPortrait});
  @override
  Widget build(BuildContext context) {
    return  Container(
      width: isPortrait ? width * 0.35 : width * 0.45,
      height: isPortrait ? height * 0.15 : height * 0.2,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFA8E6CF), // soft mint green (safe)
            Color(0xFFDCEDC1), // pale lime tone
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: isPortrait ? Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Colors.black54),
          SizedBox(height: height * 0.01),
          Text(
            text ,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 16,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ): Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Colors.black54),
          SizedBox(width: width * 0.02),
          Text(
            text ,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 16,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
