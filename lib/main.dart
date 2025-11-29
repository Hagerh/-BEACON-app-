import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projectdemo/business/cubit/networkDashboard_cubit.dart';
import 'package:projectdemo/business/cubit/network_cubit.dart';
import 'package:projectdemo/business/cubit/privateChat_cubit.dart';
import 'package:projectdemo/business/cubit/userProfile_cubit.dart';
import 'package:projectdemo/constants/colors.dart';
import 'package:projectdemo/presentation/screens/privateChat_screen.dart';
import 'package:projectdemo/presentation/screens/createNetwork_screen.dart';
import 'package:projectdemo/presentation/screens/landing_screen.dart';
import 'package:projectdemo/presentation/screens/joinNetworks_screen.dart';
import 'package:projectdemo/presentation/screens/publicChat_screen.dart';

import 'package:projectdemo/presentation/screens/profile_screen.dart';
import 'package:projectdemo/constants/settings.dart';
import 'package:projectdemo/presentation/screens/resourceSharing_screen.dart';

import 'package:projectdemo/services/p2p_service.dart';
import 'package:projectdemo/data/model/userProfile_model.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final P2PService p2pService = P2PService();
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BEACON Network',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.primaryBackground,
        primaryColor: AppColors.alertRed,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.alertRed,
          secondary: AppColors.connectionTeal,
          surface: AppColors.secondaryBackground,
          onPrimary: AppColors.textPrimary,
          onSecondary: AppColors.textPrimary,
          onSurface: AppColors.textSecondary,
        ),
      ),
      initialRoute: '/',
      routes: {
        landingScreen: (context) => LandingScreen(),

        networkScreen: (context) {
          // TODO: Get actual current user from your auth/storage
          final currentUser = UserProfile(
            name: 'My Device',
            deviceId: 'device_${DateTime.now().millisecondsSinceEpoch}',
            avatarLetter: 'M',
            avatarColor: Colors.blue,
            status: 'Active',
            email: 'user@example.com',
            phone: '+1234567890',
            address: 'Unknown',
            bloodType: 'O+',
          );

          return BlocProvider(
            create: (context) => NetworkCubit(p2pService: p2pService),

            child: Joinnetworkscreen(currentUser: currentUser),
          );
        },
        createNetworkScreen: (context) => CreateNetworkScreen(),
        profileScreen: (context) {
          // Arguments are passed when viewing a peer profile (from PrivateChatScreen)
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;

          return BlocProvider(
            // Pass arguments to the Cubit so it knows which profile to load
            create: (context) => ProfileCubit()..loadProfile(args),
            child: const ProfileScreen(),
          );
        },

        publicChatScreen: (context) {
          //Extract arguments passed from Joinnetworkscreen
          final networkData =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;

          final networkName = networkData?['networkName'] ?? 'Unknown Network';

          return BlocProvider(
            // IMMEDIATELY call loadDevices with arguments
            create: (context) => NetworkDashboardCubit(p2pService: p2pService),
            child: PublicChatScreen(networkName: networkName),
          );
        },
        chatScreen: (context) {
          //Extract arguments passed from PublicChatScreen
          final deviceInfo =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          final name = deviceInfo?['name'] ?? 'User';
          final status = deviceInfo?['status'] ?? 'Online';
          final deviceId = deviceInfo?['deviceId'] ?? 'UnknownID';

          return BlocProvider(
            // Pass  initial data to the Cubit's constructor
            create: (context) => PrivateChatCubit(
              p2pService: p2pService,

              recipientName: name,

              recipientDeviceId: deviceId,

              recipientStatus: status,
            ),

            child: const PrivatechatScreen(),
          );
        },

        resourceScreen: (context) => ResourceSharingScreen(),
      },
    );
  }
}
