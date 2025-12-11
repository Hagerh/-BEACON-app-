import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projectdemo/core/constants/colors.dart';
import 'package:projectdemo/business/cubit/user_profile_cubit.dart';
import 'package:projectdemo/business/cubit/user_profile_state.dart';
import 'package:projectdemo/presentation/widgets/profileImage_widget.dart';
import 'package:projectdemo/presentation/widgets/userInfoCard_widget.dart';
import 'package:projectdemo/presentation/widgets/voice_widget.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    //block listener to handle error states
    return BlocListener<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is ProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.alertRed,
            ),
          );
        }
      },
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
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
            body: _buildBody(context, state),
            floatingActionButton: const VoiceWidget(),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, ProfileState state) {
    if (state is ProfileLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ProfileError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.alertRed,
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final args =
                    ModalRoute.of(context)?.settings.arguments
                        as Map<String, dynamic>?;
                context.read<ProfileCubit>().loadProfile(args);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is ProfileLoaded) {
      final profile = state.profile;
      final isEditable = state.isEditable;

      return OrientationBuilder(
        builder: (context, orientation) {
          final isLandscape = orientation == Orientation.landscape;

          if (isLandscape) {
            return Row(
              children: [
                SizedBox(
                  width: 250,
                  child: ProfileimageWidget(
                    avatarLetter: profile.avatarLetter,
                    avatarColor: profile.avatarColor,
                    title: profile.name,
                    subtitle: 'Status: ${profile.status}',
                    showCamera: isEditable,
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: SingleChildScrollView(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: UserinfocardWidget(
                          name: profile.name,
                          email: profile.email,
                          phone: profile.phone,
                          address: profile.address,
                          bloodType: profile.bloodType,
                          editable: isEditable,
                          onSave: isEditable
                              ? (data) {
                                  context.read<ProfileCubit>().saveProfile(
                                    name: data['name']!,
                                    email: data['email']!,
                                    phone: data['phone']!,
                                    address: data['address']!,
                                    bloodType: data['bloodType']!,
                                  );

                                  // Show success message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Profile updated successfully!',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      backgroundColor: AppColors.safeGreen,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // Portrait mode
          return SingleChildScrollView(
            child: Center(
              child: Column(
                children: [
                  ProfileimageWidget(
                    avatarLetter: profile.avatarLetter,
                    avatarColor: profile.avatarColor,
                    title: profile.name,
                    subtitle: 'Status: ${profile.status}',
                    showCamera: isEditable,
                  ),
                  const SizedBox(height: 16),
                  UserinfocardWidget(
                    name: profile.name,
                    email: profile.email,
                    phone: profile.phone,
                    address: profile.address,
                    bloodType: profile.bloodType,
                    editable: isEditable,
                    onSave: isEditable
                        ? (data) {
                            context.read<ProfileCubit>().saveProfile(
                              name: data['name']!,
                              email: data['email']!,
                              phone: data['phone']!,
                              address: data['address']!,
                              bloodType: data['bloodType']!,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Profile updated successfully!',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                backgroundColor: AppColors.safeGreen,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        : null,
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}
