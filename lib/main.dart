import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:projectdemo/constants/colors.dart';
import 'package:projectdemo/view/screens/privateChat_screen.dart';
import 'package:projectdemo/view/screens/createNetwork_screen.dart';
import 'package:projectdemo/view/screens/landing_screen.dart';
import 'package:projectdemo/view/screens/joinNetworks_screen.dart';
import 'package:projectdemo/view/screens/publicChat_screen.dart';

import 'package:projectdemo/view/screens/profile_screen.dart';
import 'package:projectdemo/constants/settings.dart';
import 'package:projectdemo/view/screens/resourceSharing_screen.dart';

// Import ViewModels
import 'package:projectdemo/viewmodel/profile_viewmodel.dart';
import 'package:projectdemo/viewmodel/network_viewmodel.dart';
import 'package:projectdemo/viewmodel/chat_viewmodel.dart';
import 'package:projectdemo/viewmodel/resource_viewmodel.dart';

void main() {
  runApp(MyApp());
  // runApp(
  //   // Setup MultiProvider for MVVM architecture
  //   MultiProvider(
  //     providers: [
  //       ChangeNotifierProvider(create: (_) => ProfileViewModel()),
  //       ChangeNotifierProvider(create: (_) => NetworkViewModel()),
  //       ChangeNotifierProvider(create: (_) => ChatViewModel()),
  //       ChangeNotifierProvider(create: (_) => ResourceViewModel()),
  //     ],
  //     child: const MyApp(),
  //   ),
  // );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        networkScreen: (context) => Joinnetworkscreen(),
        createNetworkScreen: (context) => CreateNetworkScreen(),
        profileScreen: (context) => ProfileScreen(),
        publicChatScreen: (context) => PublicChatScreen(),
        chatScreen: (context) => PrivatechatScreen(),

        resourceScreen: (context) => ResourceSharingScreen(),
      },
    );
  }
}
