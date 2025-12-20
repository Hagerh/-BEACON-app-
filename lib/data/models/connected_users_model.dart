// CONNECTED USER MODEL
// Represents a user/device connected to the created network

class ConnectedUser {
  final String id; // User / Device ID
  final String name; // Display name

  ConnectedUser({required this.id, required this.name});

  // Creates a copy with updated fields
  ConnectedUser copyWith({String? name, String? status}) {
    return ConnectedUser(id: id, name: name ?? this.name);
  }

}
