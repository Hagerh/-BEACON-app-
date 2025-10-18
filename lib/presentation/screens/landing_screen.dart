import 'package:flutter/material.dart';
import 'package:projectdemo/presentation/widgets/landingPageButtons_widget.dart';
import 'package:projectdemo/presentation/widgets/voice_widget.dart';
import '../widgets/footer_widget.dart';

import '../widgets/homeCard_widget.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home "),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromARGB(255, 235, 200, 200),
                Color.fromARGB(255, 164, 236, 246),
              ],
            ),
          ),
        ),
      ),

      body: OrientationBuilder(
        builder: (context, orientation) {
          final isPortrait = orientation == Orientation.portrait;
          final size = MediaQuery.of(context).size;
          final width = size.width;
          final height = size.height;

          return SingleChildScrollView(
            child: isPortrait
                ? Column(
                    children: [
                      HomecardWidget(width: width, height: height, isPortrait: isPortrait),
                      SizedBox(height: height * 0.03),
                      Padding(
                        padding: EdgeInsets.all(height * 0.02),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            joinNetworkButton(
                              context,
                              width,
                              height,
                              isPortrait,
                            ),
                            SizedBox(width: width * 0.05),
                            createNetworkButton(
                              context,
                              width,
                              height,
                              isPortrait,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : IntrinsicHeight(
                  child: Column(
                      children: [
                        HomecardWidget(width: width, height: height, isPortrait: isPortrait),
                        SizedBox(width: 24),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(width* 0.02),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                joinNetworkButton(
                                  context,
                                  width,
                                  height,
                                  isPortrait,
                                ),
                                SizedBox(width: width * 0.01),
                                createNetworkButton(
                                  context,
                                  width,
                                  height,
                                  isPortrait,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                ),
          );
        },
      ),
      floatingActionButton: const VoiceWidget(),
      bottomNavigationBar: const FooterWidget(currentPage: 0),
    );
  }

  Widget joinNetworkButton(context, width, height, isPortrait) =>
      GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, '/network');
        },
        child: LandingpagebuttonsWidget(
          text: "join\nNetwork",
          icon: Icons.wifi,
          width: width,
          height: height,
          isPortrait: isPortrait,
        ),
      );

  Widget createNetworkButton(context, width, height, isPortrait) =>
      GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, '/create_network');
        },
        child: LandingpagebuttonsWidget(
          text: "Create\nNetwork",
          icon: Icons.add_circle_outline,
          width: width,
          height: height,
          isPortrait: isPortrait,
        ),
      );
}
