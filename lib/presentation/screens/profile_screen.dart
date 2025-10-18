import 'dart:math';

import 'package:flutter/material.dart';
import 'package:projectdemo/constants/colors.dart';
import 'package:projectdemo/presentation/widgets/footer_widget.dart';
import 'package:projectdemo/presentation/widgets/voice_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _bloodTypeController = TextEditingController();

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
                      SizedBox(height: height * 0.02),
                      _buildProfileImage(width, height, isPortrait),
                      SizedBox(height: height * 0.02),
                      _buildUserInfoCard(width, height, isPortrait),
                      SizedBox(height: height * 0.02),
                      _buildSaveButton(width, height, isPortrait),
                    ],
                  )
                : Row(
                    children: [
                      SizedBox(width: width * 0.01),
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            SizedBox(height: height * 0.04),
                            _buildProfileImage(width, height, isPortrait),
                            SizedBox(height: height * 0.02),
                            _buildSaveButton(width, height, isPortrait),
                            SizedBox(height: height * 0.04),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              _buildUserInfoCard(width, height, isPortrait),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
      floatingActionButton: const VoiceWidget(),
      bottomNavigationBar: const FooterWidget(currentPage: 2),
    );
  }

  Widget _buildProfileImage(width, height, isPortrait) {
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: isPortrait ? width * 0.04 : 0,
        vertical: isPortrait ? 0 : height * 0.02,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        height: isPortrait ? null : height * 0.4,
        decoration: BoxDecoration(
          color: AppColors.alertRed,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.symmetric(
          vertical: isPortrait ? height * 0.03 : height * 0.02,
          horizontal: isPortrait ? 0 : 0,
        ),
        child: isPortrait
            ? Column(
                children: [
                  _profileIconWidget(width, height, isPortrait),
                  SizedBox(height: min(width, height) * 0.02),
                  Text(
                    'Emergency Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: min(width, height) * 0.06,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: min(width, height) * 0.01),
                  Text(
                    'Keep your information updated',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: min(width, height) * 0.035,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  SizedBox(width: width * 0.04),
                  Row(
                    children: [
                      SizedBox(width: width * 0.03),
                      _profileIconWidget(width, height, isPortrait),
                      SizedBox(width: width * 0.03),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emergency\nProfile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: min(width, height) * 0.06,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: min(width, height) * 0.01),
                  Text(
                    'Keep your information updated',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: min(width, height) * 0.035,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _profileIconWidget(width, height, isPortrait) {
    return Stack(
      children: [
        CircleAvatar(
          radius: isPortrait ? width * 0.15 : height * 0.12,
          backgroundColor: AppColors.primaryBackground,
          child: Icon(
            Icons.person,
            size: isPortrait ? width * 0.2 : height * 0.15,
            color: AppColors.alertRed,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: CircleAvatar(
            radius: isPortrait ? width * 0.05 : height * 0.04,
            backgroundColor: AppColors.primaryBackground,
            child: IconButton(
              icon: Icon(
                Icons.camera_alt,
                size: isPortrait ? width * 0.05 : height * 0.04,
                color: AppColors.alertRed,
              ),
              padding: EdgeInsets.zero,
              onPressed: () {
                // TODO: Photo upload functionality
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfoCard(width, height, isPortrait) {
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: isPortrait ? width * 0.04 : 0,
        vertical: isPortrait ? 0 : height * 0.02,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isPortrait ? width * 0.02 : height * 0.01),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person, color: AppColors.alertRed),
                  SizedBox(width: 8),
                  Text(
                    'User Information',
                    style: TextStyle(
                      fontSize: min(width, height) * 0.05,
                      fontWeight: FontWeight.bold,
                      color: AppColors.alertRed,
                    ),
                  ),
                ],
              ),
              SizedBox(height: min(height, width) * 0.02),
              isPortrait
                  ? Column(
                      children: [
                        _buildTextField(
                          _nameController,
                          'Name',
                          Icons.person,
                          isPortrait,
                          height,
                          width,
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          _emailController,
                          'Email',
                          Icons.email,
                          isPortrait,
                          height,
                          width,
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          _phoneController,
                          'Phone Number',
                          Icons.phone,
                          isPortrait,
                          height,
                          width,
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          _addressController,
                          'Address',
                          Icons.home,
                          isPortrait,
                          height,
                          width,
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          _bloodTypeController,
                          'Blood Type',
                          Icons.bloodtype,
                          isPortrait,
                          height,
                          width,
                          hintText: 'e.g., O+, A-, B+',
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _buildTextField(
                                _nameController,
                                'Name',
                                Icons.person,
                                isPortrait,
                                height,
                                width,
                              ),
                              SizedBox(height: 12),
                              _buildTextField(
                                _emailController,
                                'Email',
                                Icons.email,
                                isPortrait,
                                height,
                                width,
                              ),
                              SizedBox(height: 12),
                              _buildTextField(
                                _phoneController,
                                'Phone Number',
                                Icons.phone,
                                isPortrait,
                                height,
                                width,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            children: [
                              _buildTextField(
                                _addressController,
                                'Address',
                                Icons.home,
                                isPortrait,
                                height,
                                width,
                              ),
                              SizedBox(height: 12),
                              _buildTextField(
                                _bloodTypeController,
                                'Blood Type',
                                Icons.bloodtype,
                                isPortrait,
                                height,
                                width,
                                hintText: 'e.g., O+, A-, B+',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
              SizedBox(height: min(width, height) * 0.02),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    bool isPortrait,
    height,
    width, {
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: min(height, width) * 0.02,
        ),
      ),
      validator: (value) {
        if (controller == _nameController ||
            controller == _emailController ||
            controller == _phoneController ||
            controller == _addressController) {
          if (value == null || value.isEmpty) {
            return 'Please enter your ${label.toLowerCase()}';
          }
        }
        if (controller == _emailController) {
          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!)) {
            return 'Please enter a valid email address';
          }
        }
        return null;
      },
    );
  }

  Widget _buildSaveButton(width, height, isPortrait) {
    return ElevatedButton(
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          // TODO: Process data
        }
      },
      style: ElevatedButton.styleFrom(
        minimumSize: isPortrait
            ? Size(width * (1 - 0.08), height * 0.06)
            : Size(width, 50),
        backgroundColor: AppColors.alertRed,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.symmetric(
          vertical: min(height, width) * 0.02,
          horizontal: min(height, width) * 0.1,
        ),
      ),
      child: const Text(
        'Save Changes',
        style: TextStyle(fontSize: 16, color: AppColors.primaryBackground),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bloodTypeController.dispose();
    super.dispose();
  }
}
