import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projectdemo/business/cubit/profile/user_profile_state.dart';

import 'package:projectdemo/core/constants/colors.dart';
import 'package:projectdemo/core/services/p2p_service.dart';
import 'package:projectdemo/core/services/user_id_service.dart';
import 'package:projectdemo/data/local/database_helper.dart';
import 'package:projectdemo/data/models/user_profile_model.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final P2PService? p2pService;

  ProfileCubit({this.p2pService}) : super(ProfileLoading());

  Future<void> loadProfile(Map<String, dynamic>? args) async {
    emit(ProfileLoading());

    final bool isViewingSelf = args == null || args['isSelf'] == true;

    try {
      final db = DatabaseHelper.instance;
      UserProfile? user;

      if (isViewingSelf) {
        final userId = await UserIdService.getUserId(); // Get permanent user ID

        // Try to load by user_id first (preferred)
        user = await db.getUserProfileByUserId(userId);

        if (user == null) {
          final defaultDeviceId =
              args?['deviceId']?.toString() ??
              args?['currentDeviceId']?.toString();
          user = UserProfile(
            userId: userId,
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
        final userId = args?['userId']
            ?.toString(); // Try to get user_id from args

        // Try by user_id first if available
        if (userId != null) {
          user = await db.getUserProfileByUserId(userId);
        }

        // Fallback to device_id
        if (user == null && deviceId != null) {
          user = await db.getUserProfile(deviceId.toString());
        }

        if (user == null) {
          // Create temporary profile (this is a peer without saved data)
          final peerUserId =
              userId ?? 'temp-${DateTime.now().millisecondsSinceEpoch}';
          final peerDeviceId = deviceId?.toString();
          final name = args?['name']?.toString() ?? 'Peer User';
          user = UserProfile(
            userId: peerUserId,
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

        // Broadcast updated profile to all peers
        if (p2pService != null) {
          p2pService!.currentUser = updatedProfile;
          p2pService!.broadcastProfile();
        }

        //msln - Show success message via BlocListener - present the save operation succeeded
      } catch (e) {
        emit(ProfileError('Failed to save profile: $e'));
      }
    }
  }
}
