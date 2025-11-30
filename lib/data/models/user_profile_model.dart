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
    final name = m['username']?.toString() ?? m['name']?.toString() ?? 'Unknown';
    final avatarLetter = m['avatar']?.toString() ?? 
                        (name.isNotEmpty ? name[0].toUpperCase() : '?');
    final avatarColor = _parseColor(m['color']);
    final status = m['status']?.toString() ?? 'Idle';
    final email = m['email']?.toString() ?? '';
    final phone = m['phone']?.toString() ?? '';
    final address = m['address']?.toString() ?? '';
    final bloodType = m['blood_type']?.toString() ?? m['bloodType']?.toString() ?? 'N/A';
    final deviceId = m['device_id']?.toString() ?? '';

    return UserProfile(
      name: name,
      avatarLetter: avatarLetter,
      avatarColor: avatarColor,
      status: status,
      email: email,
      phone: phone,
      address: address,
      bloodType: bloodType,
      deviceId: deviceId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': name,
      'email': email,
      'phone': phone,
      'address': address,
      'blood_type': bloodType,
      'device_id': deviceId,
      'color': _colorToHex(avatarColor),
      'avatar': avatarLetter,
    };
  }

  // Returns only the fields needed for the Users table (excludes color and avatar which belong to Devices table)
  Map<String, dynamic> toUserMap() {
    return {
      'username': name,
      'email': email,
      'phone': phone,
      'address': address,
      'blood_type': bloodType,
      'device_id': deviceId,
    };
  }

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