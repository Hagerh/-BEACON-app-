import 'package:flutter/material.dart';

class UserProfile {
  final String userId; // Permanent unique identifier for the user
  final String name;
  final String avatarLetter;
  final Color avatarColor;
  final String status;
  final String email;
  final String phone;
  final String address;
  final String bloodType;
  final String? deviceId; // Temporary P2P session ID (null when disconnected)
  final String emergencyContact;

  UserProfile({
    required this.userId,
    required this.name,
    required this.avatarLetter,
    required this.avatarColor,
    required this.status,
    required this.email,
    required this.phone,
    required this.address,
    required this.bloodType,
    this.deviceId, // Optional - null when user is disconnected
    required this.emergencyContact,
  });

  // Parse color from hex string (e.g. #FF8A00) or int
  static Color _parseColor(dynamic v) {
    if (v == null) return const Color(0xFF000000);
    if (v is int) return Color(v);
    if (v is String) {
      final s = v;
      if (s.startsWith('#')) {
        final hex = s.substring(1);
        try {
          final value = int.parse(hex, radix: 16);
          if (hex.length == 6) return Color(0xFF000000 | value);
          if (hex.length == 8) return Color(value);
        } catch (_) {}
      }
    }
    return const Color(0xFF000000);
  }

  // Convert color to hex string
  static String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  factory UserProfile.fromMap(Map<String, dynamic> m) {
    final userId = m['user_id']?.toString() ?? m['userId']?.toString() ?? '';
    final name =
        m['username']?.toString() ?? m['name']?.toString() ?? 'Unknown';
    final avatarLetter =
        m['avatar']?.toString() ??
        (name.isNotEmpty ? name[0].toUpperCase() : '?');
    final avatarColor = _parseColor(m['color']);
    final status = m['status']?.toString() ?? 'Idle';
    final email = m['email']?.toString() ?? '';
    final phone = m['phone']?.toString() ?? '';
    final address = m['address']?.toString() ?? '';
    final bloodType =
        m['blood_type']?.toString() ?? m['bloodType']?.toString() ?? 'N/A';
    final deviceId = m['device_id']
        ?.toString(); // Can be null when user is disconnected
    final emergencyContact = m['emergency_contact']?.toString() ?? '';

    return UserProfile(
      userId: userId,
      name: name,
      avatarLetter: avatarLetter,
      avatarColor: avatarColor,
      status: status,
      email: email,
      phone: phone,
      address: address,
      bloodType: bloodType,
      deviceId: deviceId,
      emergencyContact: emergencyContact,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'username': name,
      'email': email,
      'phone': phone,
      'address': address,
      'blood_type': bloodType,
      'device_id': deviceId,
      'color': _colorToHex(avatarColor),
      'avatar': avatarLetter,
      'emergency_contact': emergencyContact,
    };
  }

  // Returns only the fields needed for the Users table (excludes color and avatar which belong to Devices table)
  Map<String, dynamic> toUserMap() {
    return {
      'user_id': userId,
      'username': name,
      'email': email,
      'phone': phone,
      'address': address,
      'blood_type': bloodType,
      'device_id': deviceId,
      'emergency_contact': emergencyContact,
    };
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? bloodType,
    Color? avatarColor,
    String? emergencyContact,
    String? deviceId,
  }) {
    return UserProfile(
      userId: userId, // userId is permanent and never changes
      name: name ?? this.name,
      avatarLetter: name != null ? name[0].toUpperCase() : avatarLetter,
      avatarColor: avatarColor ?? this.avatarColor,
      status: status, // Status  (active, idle, offline)
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      bloodType: bloodType ?? this.bloodType,
      deviceId: deviceId ?? this.deviceId,
      emergencyContact: emergencyContact ?? this.emergencyContact,
    );
  }
}
