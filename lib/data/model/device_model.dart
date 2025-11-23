
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
}