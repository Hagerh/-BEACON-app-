import 'package:flutter/material.dart';
import 'package:projectdemo/data/model/userProfile_model.dart';

@immutable
abstract class ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserProfile profile;
  final bool isEditable; // True if viewing self, False if viewing another user

  ProfileLoaded({required this.profile, required this.isEditable});

  ProfileLoaded copyWith({UserProfile? profile}) {
    return ProfileLoaded(
      profile: profile ?? this.profile,
      isEditable: isEditable,
    );
  }
}

class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}