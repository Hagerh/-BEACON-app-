import 'dart:ui';

class DeviceDetail {
  final String name;
  final String deviceId;
  final String status;
  final int unread;
  final int signalStrength;
  final String distance;
  final String avatar;
  final Color color;

  DeviceDetail({
    required this.name,
    required this.deviceId,
    required this.status,
    required this.unread,
    required this.signalStrength,
    required this.distance,
    required this.avatar,
    required this.color,
  });

  factory DeviceDetail.fromMap(Map<String, dynamic> m) {
    // parse color which may be stored as hex string (e.g. #FF8A00) or as int
    Color parseColor(dynamic v) {
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

    return DeviceDetail(
      name: m['name']?.toString() ?? 'Unknown',
      deviceId: m['device_id']?.toString() ?? 'unknown',
      status: m['status']?.toString() ?? 'Idle',
      unread: (m['unread'] is int)
          ? m['unread'] as int
          : int.tryParse(m['unread']?.toString() ?? '0') ?? 0,
      signalStrength: (m['signal_strength'] is int)
          ? m['signal_strength'] as int
          : int.tryParse(m['signal_strength']?.toString() ?? '0') ?? 0,
      distance: m['distance']?.toString() ?? '--',
      avatar: m['avatar']?.toString() ?? '?',
      color: parseColor(m['color']),
    );
  }

  //to deal with individual device updates
  DeviceDetail copyWith({
    String? status,
    int? unread,
    int? signalStrength,
    String? distance,
  }) {
    return DeviceDetail(
      name: name,
      deviceId: deviceId,
      status: status ?? this.status,
      unread: unread ?? this.unread,
      signalStrength: signalStrength ?? this.signalStrength,
      distance: distance ?? this.distance,
      avatar: avatar,
      color: color,
    );
  }

  //so in the screen
  //-> final connected = devices
  //.where((d) => d.status == 'Active')
  // .length;
}
