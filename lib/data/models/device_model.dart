class Device {
  final String id;
  final String status;
  final String network_name;
  final int connectors;

  Device({
    required this.id,
    required this.status,
    required this.network_name,
    required this.connectors,
  });

  factory Device.fromMap(Map<String, dynamic> m) {
    return Device(
      id:
          m['id']?.toString() ??
          (m['device_id']?.toString()) ??
          (m['network_name']?.toString()) ??
          '',
      status:
          m['status']?.toString() ?? m['host_status']?.toString() ?? 'Active',
      connectors: (m['connectors'] is int)
          ? m['connectors'] as int
          : int.tryParse(m['connectors']?.toString() ?? '0') ?? 0,
      network_name: m['network_name']?.toString() ?? 'Unknown', //todo remove
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'status': status,
      'connectors': connectors,
    };
  }
}
