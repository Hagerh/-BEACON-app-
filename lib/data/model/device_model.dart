
class Device {
  final String id;
  final String status; 
  final String lastSeen;
  final int connectors;

  Device({
    required this.lastSeen,
    required this.id,
    required this.status,
    required this.connectors,
  });

  factory Device.fromMap(Map<String, dynamic> m) {
    return Device(
      id: m['id']?.toString()
          ?? (m['device_id']?.toString())
          ?? (m['network_name']?.toString())
          ?? '',
      status: m['status']?.toString()
          ?? m['host_status']?.toString()
          ?? 'Unknown',
      lastSeen: m['last_seen_at']?.toString() ?? (m['lastSeen']?.toString() ?? ''),
      connectors: (m['connectors'] is int)
          ? m['connectors'] as int
          : int.tryParse(m['connectors']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'status': status,
      'last_seen_at': lastSeen,
      'connectors': connectors,
    };
  }
}
