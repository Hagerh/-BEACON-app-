import 'package:flutter/material.dart';
import 'package:projectdemo/presentation/widgets/landingPageButtons_widget.dart';

import '../../constants/colors.dart';
import '../widgets/appBar_widget.dart';
import '../widgets/beaconLogo_widget.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppbarWidget(),
          SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // TODO: handle Join action
                    },
                    child: LandingpagebuttonsWidget(
                      text: "join\nNetwork",
                      icon: Icons.wifi,
                    ),
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // TODO: handle Create action
                    },
                    child: LandingpagebuttonsWidget(
                      text: "Create\nNetwork",
                      icon: Icons.add_circle_outline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(" Say 'Join network' or 'Create network' to continue"),
                duration: Duration(seconds: 2),
              ),
            );
          },
          tooltip: 'Say "Join network" \n or "Create network" to continue',
          backgroundColor: AppColors.buttonPrimary,
          child: const Icon(Icons.mic, color: AppColors.primaryBackground),
        ),
    );
  }
}
