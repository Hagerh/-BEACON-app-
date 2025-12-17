import 'package:flutter/material.dart';

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

// Contains network info
class CreateNetworkActive extends CreateNetworkState {
  final String networkName;
  final int maxConnections;

  CreateNetworkActive({
    required this.networkName,
    required this.maxConnections,
  });
}

// Error state when network creation or management fails
class CreateNetworkError extends CreateNetworkState {
  final String message;

  // Previous state before error occurred
  final CreateNetworkState? previousState;

  CreateNetworkError({required this.message, this.previousState});
}
