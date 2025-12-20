import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projectdemo/core/services/user_id_service.dart';
import 'package:projectdemo/core/services/p2p_service.dart';
import 'package:projectdemo/data/local/database_helper.dart';
import 'package:projectdemo/data/models/user_profile_model.dart';
import 'package:projectdemo/business/cubit/network_discovery/network_discovery_cubit.dart';
import 'package:projectdemo/presentation/screens/join_networks_screen.dart';
import 'package:projectdemo/core/constants/colors.dart';

/// Loader screen that fetches user profile before showing network discovery
class NetworkLoaderScreen extends StatelessWidget {
  final P2PService p2pService;

  const NetworkLoaderScreen({super.key, required this.p2pService});

  Future<UserProfile> _loadUserProfile() async {
    final userId =
        await UserIdService.getUserId(); // Get or generate permanent user ID
    final db = DatabaseHelper.instance;

    // Try to load existing profile by user_id (supports reconnection)
    UserProfile? user = await db.getUserProfileByUserId(userId);

    // If not found, create default profile
    if (user == null) {
      user = UserProfile(
        userId: userId, // Permanent user ID
        emergencyContact: '',
        name: 'My Device',
        deviceId: null, // Will be set when joining P2P network
        avatarLetter: 'M',
        avatarColor: Colors.blue,
        status: 'Active',
        email: 'user@example.com',
        phone: '+1234567890',
        address: 'Unknown',
        bloodType: 'O+',
      );

      // Save to database
      await db.saveUserProfile(user);
    }

    return user;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile>(
      future: _loadUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.connectionTeal),
                  const SizedBox(height: 16),
                  Text(
                    'Loading profile...',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                'Error loading profile: ${snapshot.error}',
                style: TextStyle(color: AppColors.alertRed),
              ),
            ),
          );
        }

        final currentUser = snapshot.data!;

        return BlocProvider(
          create: (context) => NetworkCubit(p2pService: p2pService),
          child: Joinnetworkscreen(currentUser: currentUser),
        );
      },
    );
  }
}
