import 'dart:ui';

class DeviceDetail {
  final String name;
  final String deviceId;
  final String status;
  final int signalStrength;
  final String avatar;
  final DateTime last_seen_at;
  final Color color;

  DeviceDetail({
    required this.name,
    required this.deviceId,
    required this.status,
    required this.signalStrength,
    required this.avatar,
    required this.last_seen_at
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
      signalStrength: (m['signal_strength'] is int)
          ? m['signal_strength'] as int
          : int.tryParse(m['signal_strength']?.toString() ?? '0') ?? 0,
      last_seen_at: DateTime.parse(m['last_seen_at']?.toString() ?? '0'),
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

  /// Compare device IDs and key properties (excluding timestamps which change frequently)
  static bool areListsEqual(
    List<DeviceDetail> list1,
    List<DeviceDetail> list2,
  ) {
    if (list1.length != list2.length) return false;

    // Create maps for quick lookup
    final map1 = {for (var d in list1) d.deviceId: d};
    final map2 = {for (var d in list2) d.deviceId: d};

    // Check if all device IDs match
    if (!map1.keys.toSet().containsAll(map2.keys)) return false;

    // Check if key properties match for each device
    for (var deviceId in map1.keys) {
      final d1 = map1[deviceId]!;
      final d2 = map2[deviceId]!;

      if (d1.name != d2.name ||
          d1.status != d2.status ||
          d1.signalStrength != d2.signalStrength ||
          d1.avatar != d2.avatar ||
          d1.color != d2.color) {
        return false;
      }
    }

    return true;
  }
}