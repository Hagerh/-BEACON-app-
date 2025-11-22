import 'package:flutter/material.dart';
import 'package:projectdemo/presentation/widgets/profileImage_widget.dart';
import 'package:projectdemo/presentation/widgets/userInfoCard_widget.dart';
import 'package:projectdemo/presentation/widgets/voice_widget.dart';

class ProfileScreen extends StatelessWidget {
  final String? name;
  final String? avatarLetter;
  final Color? avatarColor;
  final String? status;
  final String? email;
  final String? phone;
  final String? address;
  final String? bloodType;

  const ProfileScreen({
    super.key,
    this.name,
    this.avatarLetter,
    this.avatarColor,
    this.status,
    this.email,
    this.phone,
    this.address,
    this.bloodType,
  });

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;

 
  final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
  // for sake of compatibility with navigation that passes arguments                 !IMPORTANT BY JOJO ASK TEAM
  final displayName = name ?? args?['name'] as String? ?? 'Emergency Profile';
  final displayAvatar = avatarLetter ?? args?['avatar'] as String? ?? 'U';
  final displayColor = avatarColor ?? args?['color'] as Color? ?? Colors.blue;
  final displayStatus = status ?? args?['status'] as String? ?? 'Active';

  return Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                icon: const Icon(Icons.home_outlined),
                tooltip: 'Home',
                onPressed: () {
                  Navigator.pushReplacementNamed(context, "/");
                },
              ),
            ],
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
                    SizedBox(
                      width: 250,
                      child: ProfileimageWidget(
                        avatarLetter: displayAvatar,
                        avatarColor: displayColor,
                        title: displayName,
                        subtitle: 'Status: $displayStatus',
                        showCamera: args == null,
                      ),
                    ),

                    const VerticalDivider(width: 1),

                    Expanded(
                      child: SingleChildScrollView(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: UserinfocardWidget(
                              name: displayName,
                              email: email ?? args?['email'] as String? ?? '',
                              phone: phone ?? args?['phone'] as String? ?? '',
                              address: address ?? args?['address'] as String? ?? '',
                              bloodType: bloodType ?? args?['bloodType'] as String? ?? '',
                              editable: args == null,
                            ),
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
                        ProfileimageWidget(
                          avatarLetter: displayAvatar,
                          avatarColor: displayColor,
                          title: displayName,
                          subtitle: 'Status: $displayStatus',
                          showCamera: args == null,
                        ),
                        const SizedBox(height: 16),
                        UserinfocardWidget(
                          name: displayName,
                          email: email ?? args?['email'] as String? ?? '',
                          phone: phone ?? args?['phone'] as String? ?? '',
                          address: address ?? args?['address'] as String? ?? '',
                          bloodType: bloodType ?? args?['bloodType'] as String? ?? '',
                          editable: args == null,
                        ),
                      ],
                    ),
                  ),
                ),

          floatingActionButton: const VoiceWidget(),

          
        );
      },
    );
  }
}
