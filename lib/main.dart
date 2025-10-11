import 'package:flutter/material.dart';
import 'package:projectdemo/constants/colors.dart';
import 'package:projectdemo/presentation/screens/landing_screen.dart';
import 'presentation/router.dart';

void main() {
  runApp(MyApp(appRouter: AppRouter(),));
}

class MyApp extends StatelessWidget {
  final AppRouter appRouter;
  const MyApp({super.key, required this.appRouter });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
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
      home: const LandingScreen(),
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}

