import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LandingpagebuttonsWidget extends StatelessWidget {
  final IconData icon;
  final String text;

  const LandingpagebuttonsWidget({super.key, required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return  Container(
      width: 140,
      height: 140,
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
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Colors.black54),
          SizedBox(height: 10),
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
