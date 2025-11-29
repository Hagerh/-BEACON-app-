// CONNECTED USER MODEL
// Represents a user/device connected to the created network

class ConnectedUser {
  final String id; // User / Device ID
  final String name; // Display name
  final DateTime joinedAt;

  ConnectedUser({required this.id, required this.name, required this.joinedAt});

  // Creates a copy with updated fields
  ConnectedUser copyWith({String? name, String? status}) {
    return ConnectedUser(id: id, name: name ?? this.name, joinedAt: joinedAt);
  }

  // Formats joined time for display
  String get formattedJoinTime {
    final hour = joinedAt.hour.toString().padLeft(2, '0');
    final minute = joinedAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
