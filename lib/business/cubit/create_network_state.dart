import 'package:flutter/material.dart';
import 'package:projectdemo/data/models/connected_users_model.dart';

@immutable
abstract class CreateNetworkState {}

// When user opens the Create Network screen
class CreateNetworkInitial extends CreateNetworkState {}

// Loading state when network is being initialized
class CreateNetworkStarting extends CreateNetworkState {
  final String networkName;
  final int maxConnections;

  CreateNetworkStarting({
    required this.networkName,
    required this.maxConnections,
  });
}

// One-shot state for navigation
class CreateNetworkReady extends CreateNetworkState {
  final String networkName;

  CreateNetworkReady({required this.networkName});
}

// Contains network info and list of connected users
class CreateNetworkActive extends CreateNetworkState {
  final String networkName;
  final int maxConnections;
  final List<ConnectedUser> connectedUsers;

  CreateNetworkActive({
    required this.networkName,
    required this.maxConnections,
    required this.connectedUsers,
  });

  // Creates a copy with updated user list, used when users join or leave the network
  CreateNetworkActive copyWith({List<ConnectedUser>? connectedUsers}) {
    return CreateNetworkActive(
      networkName: networkName,
      maxConnections: maxConnections,
      connectedUsers: connectedUsers ?? this.connectedUsers,
    );
  }

  // Connection count getter
  int get currentConnections => connectedUsers.length;

  bool get isFull => connectedUsers.length >= maxConnections;
}

// Error state when network creation or management fails
class CreateNetworkError extends CreateNetworkState {
  final String message;

  // Previous state before error occurred
  final CreateNetworkState? previousState;

  CreateNetworkError({required this.message, this.previousState});
}
