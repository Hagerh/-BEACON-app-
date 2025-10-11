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
              colors: [Color.fromARGB(255, 235, 200, 200), Color.fromARGB(255, 164, 236, 246)],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          HomecardWidget(),
          SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/network');
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
      floatingActionButton: const VoiceWidget(),
      bottomNavigationBar: const FooterWidget(currentPage: 0),
    );
  }
}
