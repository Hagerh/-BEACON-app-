import 'package:flutter/material.dart';
import 'package:projectdemo/core/constants/colors.dart';
import 'package:projectdemo/presentation/widgets/beaconLogo_widget.dart';
import 'package:projectdemo/presentation/widgets/landingPageButtons_widget.dart';
import 'package:projectdemo/presentation/widgets/voice_widget.dart';
import 'package:projectdemo/presentation/widgets/homeCard_widget.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  Widget _buildMainContent(BuildContext context, bool isLandscape) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isLandscape) ...[
          const HomecardWidget(),
          const SizedBox(height: 24),
        ],
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isLandscape ? 32.0 : 16.0,
            vertical: isLandscape ? 0 : 16.0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/network'),
                  child: const LandingpagebuttonsWidget(
                    text: "join\nNetwork",
                    icon: Icons.wifi,
                  ),
                ),
              ),
              SizedBox(width: isLandscape ? 32 : 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/create_network'),
                  child: const LandingpagebuttonsWidget(
                    text: "Create\nNetwork",
                    icon: Icons.add_circle_outline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (isLandscape) {
      return Center(child: content);
    } else {
      // In portrait, we use SingleChildScrollView to ensure scrollability.
      return SingleChildScrollView(child: content);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;

        return Scaffold(
          appBar: AppBar(
            actions: isLandscape
                ? []
                : [
                    IconButton(
                      icon: const Icon(Icons.person_outline),
                      tooltip: 'Profile',

                      onPressed: () {
                        Navigator.pushReplacementNamed(context, "/profile");
                      },
                    ),
                  ],
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

          body: isLandscape
              ? Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFE6E6), Color(0xFFE0F7FA)],
                        ),
                      ),
                      width: 300,
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.0),
                            child: BeaconLogo(),
                          ),

                          const Divider(
                            color: Color.fromARGB(255, 229, 228, 228),
                          ),

                          ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: const Text("Profile"),
                            onTap: () {
                              Navigator.pushReplacementNamed(
                                context,
                                "/profile",
                              );
                            },
                            selectedTileColor: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                          ),

                          // Spacer to push the Exit button to the bottom
                          const Spacer(),

                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: ListTile(
                              leading: const Icon(
                                Icons.logout,
                                color: AppColors.alertRed,
                              ),
                              title: const Text(
                                "Leave",
                                style: TextStyle(color: AppColors.alertRed),
                              ),
                              onTap: () {
                                // Placeholder for actual logout leave logic
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Leave functionality Tapped!',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const VerticalDivider(width: 1),

                    Expanded(child: _buildMainContent(context, true)),
                  ],
                )
              : _buildMainContent(context, false),

          floatingActionButton: const VoiceWidget(),
        );
      },
    );
  }
}
