  import 'package:flutter/material.dart';
import 'package:projectdemo/constants/colors.dart';
class ProfileimageWidget extends StatelessWidget {
  const ProfileimageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return   Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.alertRed,
     
      ),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primaryBackground,
                child: Icon(Icons.person, size: 60, color: AppColors.alertRed),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryBackground,
                  child: IconButton(
                    icon: Icon(
                      Icons.camera_alt,
                      size: 18,
                      color: AppColors.alertRed,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      // TODO: Photo upload functionality
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Emergency Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Keep your information updated',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
