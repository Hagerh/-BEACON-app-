import 'package:flutter/material.dart';
import 'package:projectdemo/presentation/widgets/footer_widget.dart';
import 'package:projectdemo/presentation/widgets/profileImage_widget.dart';
import 'package:projectdemo/presentation/widgets/userInfoCard_widget.dart';
import 'package:projectdemo/presentation/widgets/voice_widget.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;

        return Scaffold(
          appBar: AppBar(
            title: const Text("Profile"),
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
          body: isLandscape
              ? Row(
                  children: [
                    SizedBox(width: 250, child: const ProfileimageWidget()),

                    const VerticalDivider(width: 1),

                    Expanded(
                      child: SingleChildScrollView(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: UserinfocardWidget(),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  child: Center(
                    child: Column(
                      children: [
                        const ProfileimageWidget(),
                        const SizedBox(height: 16),
                        UserinfocardWidget(),
                      ],
                    ),
                  ),
                ),

          floatingActionButton: const VoiceWidget(),

          //Todo will be removed
          bottomNavigationBar: isLandscape
              ? null
              : const FooterWidget(currentPage: 2),
        );
      },
    );
  }
}
