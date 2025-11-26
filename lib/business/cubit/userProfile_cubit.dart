import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projectdemo/constants/colors.dart';
import 'package:projectdemo/data/model/userProfile_model.dart';
import 'package:projectdemo/business/cubit/userProfile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(ProfileLoading());

  // Simulates fetching profile data based on arguments
  Future<void> loadProfile(Map<String, dynamic>? args) async {
    emit(ProfileLoading());

    // If args is null, we assume the user is viewing their own profile.
    final bool isViewingSelf = args == null || args['isSelf'] == true; 

    try {
      UserProfile user;
      
      if (isViewingSelf) {
        // ---  (Editable) ---
        // TODO: Replace with actual SQLite/Device ID fetch 
        user = UserProfile(
          name: 'Current User',
          avatarLetter: 'C',
          avatarColor: AppColors.connectionTeal,
          status: 'Active',
          email: 'user@beacon.net',
          phone: '01234567890',
          address: '123 Main St, Zone A',
          bloodType: 'O+',
          deviceId: 'DEVICE-OWNER-ID',
        );
      } else {
        // --- (Read-Only) ---
        user = UserProfile(
          name: args['name'] ?? 'Peer User',
          avatarLetter: args['avatar'] ?? 'P',
          avatarColor: args['color'] ?? Colors.grey,
          status: args['status'] ?? 'Idle',
          email: args['email'] ?? '',
          phone: args['phone'] ?? '',
          address: args['address'] ?? 'Unknown location',
          bloodType: args['bloodType'] ?? 'N/A',
          deviceId: args['deviceId'] ?? 'DEVICE-PEER-ID',
        );
      }

      emit(ProfileLoaded(profile: user, isEditable: isViewingSelf));

    } catch (e) {
      emit(ProfileError('Failed to load profile: $e'));
    }
  }

  
  Future<void> saveProfile({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String bloodType,
  }) async {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      
      
      final updatedProfile = currentState.profile.copyWith(
        name: name,
        email: email,
        phone: phone,
        address: address,
        bloodType: bloodType,
      );
      
      emit(currentState.copyWith(profile: updatedProfile));

      // TODO: Implement actual database  (SQLite) 
       
      
      //msln - Show success message via BlocListener - present the save operation succeeded
    }
  }
}