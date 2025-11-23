import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projectdemo/business/bloc/cubit/network_cubit.dart';
import 'package:projectdemo/constants/colors.dart';
import 'package:projectdemo/presentation/screens/privateChat_screen.dart';
import 'package:projectdemo/presentation/screens/createNetwork_screen.dart';
import 'package:projectdemo/presentation/screens/landing_screen.dart';
import 'package:projectdemo/presentation/screens/joinNetworks_screen.dart';
import 'package:projectdemo/presentation/screens/publicChat_screen.dart';

import 'package:projectdemo/presentation/screens/profile_screen.dart';
import 'package:projectdemo/constants/settings.dart';
import 'package:projectdemo/presentation/screens/resourceSharing_screen.dart';

void main() {
  runApp(MyApp());
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
        networkScreen: (context) => BlocProvider(
          create: (context) => NetworkCubit()..loadNetworks(), 
          child: const Joinnetworkscreen(),
        ),
        createNetworkScreen: (context) => CreateNetworkScreen(),
        profileScreen: (context) => ProfileScreen(),
        publicChatScreen: (context) => PublicChatScreen(),
        chatScreen: (context) => PrivatechatScreen(),

        resourceScreen: (context) => ResourceSharingScreen(),
      },
    
    );
  }
}
