import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import 'beaconLogo_widget.dart';

class HomecardWidget extends StatelessWidget {
  final double width;
  final double height;
  final bool isPortrait;

  const HomecardWidget({
    super.key,
    required this.width,
    required this.height,
    required this.isPortrait,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: isPortrait? height * 0.35 : height * 0.3,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE6E6), Color(0xFFE0F7FA)],
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isPortrait
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BeaconLogo(width: width, height: height, isPortrait: isPortrait),
                SizedBox(height: height * 0.01),
                Flexible(
                  child: Text(
                    "Offline Emergency Communication Network",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: width * 0.04,
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            )
          : Padding(
              padding: EdgeInsets.only(left: width * 0.01),
              child: Row(
                children: [
                  Expanded(flex: 1, child: BeaconLogo(width: width, height: height, isPortrait: isPortrait)),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Offline Emergency Communication Network",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: width * 0.03,
                          fontWeight: FontWeight.bold,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
