import 'package:flutter/material.dart';

class UserProfile {
  final String name;
  final String avatarLetter;
  final Color avatarColor;
  final String status;
  final String email;
  final String phone;
  final String address;
  final String bloodType;
  final String deviceId; // Unique identifier  -> for P2P and Database

  UserProfile({
    required this.name,
    required this.avatarLetter,
    required this.avatarColor,
    required this.status,
    required this.email,
    required this.phone,
    required this.address,
    required this.bloodType,
    required this.deviceId,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? bloodType,
    Color? avatarColor,
  }) {
    return UserProfile(
      name: name ?? this.name,
      avatarLetter: name != null ? name[0].toUpperCase() : avatarLetter,
      avatarColor: avatarColor ?? this.avatarColor,
      status: status, // Status  (active, idle, offline)
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      bloodType: bloodType ?? this.bloodType,
      deviceId: deviceId,
    );
  }
}