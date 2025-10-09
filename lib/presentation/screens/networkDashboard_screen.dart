import 'package:flutter/material.dart';
import 'package:projectdemo/presentation/widgets/landingPageButtons_widget.dart';

import '../../constants/colors.dart';
import '../widgets/appBar_widget.dart';
import '../widgets/beaconLogo_widget.dart';

class NetworkDashboardScreen extends StatefulWidget {
  const NetworkDashboardScreen({super.key});

  @override
  State<NetworkDashboardScreen> createState() => _NetworkDashboardScreenState();
}

class _NetworkDashboardScreenState extends State<NetworkDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.safeGreen,
          title: Text("Stay connected, Stay safe"),
        ),
        body:Column(
          children: [
            Text("data"),
          ],
        )
    );
  }
}
