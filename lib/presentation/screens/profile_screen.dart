import 'package:flutter/material.dart';
import 'package:projectdemo/presentation/widgets/footer_widget.dart';
import 'package:projectdemo/presentation/widgets/profileImage_widget.dart';
import 'package:projectdemo/presentation/widgets/userInfoCard_widget.dart';
import 'package:projectdemo/presentation/widgets/voice_widget.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
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
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const ProfileimageWidget(),
              SizedBox(height: 16),
              UserinfocardWidget(), 
            
            ],
          ),
        ),
      ),
      floatingActionButton: const VoiceWidget(),
      bottomNavigationBar: const FooterWidget(currentPage: 2),
    );
  }
}