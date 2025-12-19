import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projectdemo/core/constants/colors.dart';
import 'package:projectdemo/data/local/database_helper.dart';
import 'package:projectdemo/data/models/user_profile_model.dart';
import 'package:projectdemo/business/cubit/user_profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(ProfileLoading());

  Future<void> loadProfile(Map<String, dynamic>? args) async {
    emit(ProfileLoading());

    final bool isViewingSelf = args == null || args['isSelf'] == true;

    try {
      final db = DatabaseHelper.instance;
      UserProfile? user;

      if (isViewingSelf) {
        final deviceId = args?['deviceId'] ?? args?['currentDeviceId'] ?? 'DEVICE-OWNER-ID'; // Fallback to default owner ID

        
          user = await db.getUserProfile(deviceId.toString());
        

     
        if (user == null) {
          final defaultDeviceId = deviceId?.toString() ?? 'DEVICE-OWNER-ID';
          user = UserProfile(
            emergencyContact: '',
            name: 'Current User',
            avatarLetter: 'C',
            avatarColor: AppColors.connectionTeal,
            status: 'Active',
            email: '',
            phone: '',
            address: '',
            bloodType: '',
            deviceId: defaultDeviceId,
          );
        }
      } else {
        final deviceId = args?['deviceId'];

        if (deviceId != null) {
          user = await db.getUserProfile(deviceId.toString());
        }

        if (user == null) {
          final peerDeviceId = deviceId?.toString() ?? 'DEVICE-PEER-ID';
          final name = args?['name']?.toString() ?? 'Peer User';
          user = UserProfile(
            emergencyContact: '',
            name: name,
            avatarLetter:
                args?['avatar']?.toString() ??
                (name.isNotEmpty ? name[0].toUpperCase() : 'P'),
            avatarColor: args?['color'] is Color
                ? args!['color'] as Color
                : (args?['color'] is String
                      ? _parseColorFromString(args!['color'] as String)
                      : Colors.grey),
            status: args?['status']?.toString() ?? 'Idle',
            email: args?['email']?.toString() ?? '',
            phone: args?['phone']?.toString() ?? '',
            address: args?['address']?.toString() ?? 'Unknown location',
            bloodType: args?['bloodType']?.toString() ?? 'N/A',
            deviceId: peerDeviceId,
          );
        }
      }

      emit(ProfileLoaded(profile: user, isEditable: isViewingSelf));
    } catch (e) {
      emit(ProfileError('Failed to load profile: $e'));
    }
  }

  Color _parseColorFromString(String colorString) {
    if (colorString.startsWith('#')) {
      final hex = colorString.substring(1);
      try {
        final value = int.parse(hex, radix: 16);
        if (hex.length == 6) return Color(0xFF000000 | value);
        if (hex.length == 8) return Color(value);
      } catch (_) {}
    }
    return Colors.grey;
  }

  Future<void> saveProfile({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String bloodType,
    required String emergencyContact,
  }) async {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;

      try {
        final updatedProfile = currentState.profile.copyWith(
          name: name,
          email: email,
          phone: phone,
          address: address,
          bloodType: bloodType,
          emergencyContact: emergencyContact,
        );

        final db = DatabaseHelper.instance;
        await db.saveUserProfile(updatedProfile);

        emit(currentState.copyWith(profile: updatedProfile));

        //msln - Show success message via BlocListener - present the save operation succeeded
      } catch (e) {
        emit(ProfileError('Failed to save profile: $e'));
      }
    }
  }
}
