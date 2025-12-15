import 'package:flutter/material.dart';
import 'package:projectdemo/core/constants/colors.dart';

class VoiceWidget extends StatelessWidget {
  const VoiceWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      // FIX: Set heroTag to null to prevent Hero animation conflicts with Tooltip
      heroTag: null,
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              " Say 'Join network' or 'Create network' to continue",
            ),
            duration: Duration(seconds: 2),
          ),
        );
      },
      tooltip: 'Say "Join network" \n or "Create network" to continue',
      backgroundColor: AppColors.buttonPrimary,
      child: const Icon(Icons.mic, color: AppColors.primaryBackground),
    );
  }
}
