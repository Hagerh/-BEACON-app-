import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projectdemo/core/constants/colors.dart';
import 'package:projectdemo/core/services/p2p_service.dart';
import 'package:projectdemo/business/cubit/private_chat_cubit.dart';
import 'package:projectdemo/business/cubit/user_profile_cubit.dart';
import 'package:projectdemo/business/cubit/create_network_cubit.dart';
import 'package:projectdemo/business/cubit/network_dashboard_cubit.dart';
import 'package:projectdemo/presentation/routes/app_routes.dart';
import 'package:projectdemo/presentation/screens/landing_screen.dart';
import 'package:projectdemo/presentation/screens/profile_screen.dart';
import 'package:projectdemo/presentation/screens/network_dashboard_screen.dart';
import 'package:projectdemo/presentation/screens/private_chat_screen.dart';
import 'package:projectdemo/presentation/screens/create_network_screen.dart';
import 'package:projectdemo/presentation/screens/network_settings_screen.dart';
import 'package:projectdemo/presentation/screens/resource_sharing_screen.dart';
import 'package:projectdemo/presentation/screens/splash_screen.dart';
import 'package:projectdemo/presentation/screens/network_loader_screen.dart';

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
      initialRoute: splashScreen,
      routes: {
        splashScreen: (context) => const SplashScreen(),
        landingScreen: (context) => const LandingScreen(),

        networkScreen: (context) {
          // Use loader screen to fetch user profile asynchronously
          return NetworkLoaderScreen(p2pService: p2pService);
        },
        createNetworkScreen: (context) {
          return BlocProvider(
            create: (context) => CreateNetworkCubit(p2pService: p2pService),
            child: const CreateNetworkScreen(),
          );
        },
        networkSettingsScreen: (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          final networkName =
              args?['networkName']?.toString() ?? 'Unknown Network';

          return BlocProvider(
            create: (context) =>
                NetworkDashboardCubit(p2pService: p2pService)
                  ..startListening(networkName),
            child: const NetworkSettingsScreen(),
          );
        },
        profileScreen: (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;

          return BlocProvider(
            create: (context) => ProfileCubit()..loadProfile(args),
            child: const ProfileScreen(),
          );
        },
        networkDashboardScreen: (context) {
          final networkData =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          final networkName = networkData?['networkName'] ?? 'Unknown Network';

          return BlocProvider(
            create: (context) => NetworkDashboardCubit(p2pService: p2pService),
            child: NetworkDashboardScreen(networkName: networkName),
          );
        },
        chatScreen: (context) {
          final deviceInfo =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          final name = deviceInfo?['name'] ?? 'User';
          final status = deviceInfo?['status'] ?? 'Online';
          final deviceId = deviceInfo?['deviceId'] ?? 'UnknownID';
          final networkId = deviceInfo?['networkId'] as int?;
          final currentDeviceId = deviceInfo?['currentDeviceId'] as String?;

          return BlocProvider(
            create: (context) => PrivateChatCubit(
              p2pService: p2pService,
              recipientName: name,
              recipientDeviceId: deviceId,
              recipientStatus: status,
              networkId: networkId,
              currentDeviceId: currentDeviceId,
            ),
            child: PrivatechatScreen(),
          );
        },
        resourceScreen: (context) => ResourceSharingScreen(),
      },
    );
  }
}
