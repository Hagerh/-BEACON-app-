// Create P2P network as host
// Manage connected users (add/remove)
// Handle network stop
// Integrate with P2PService

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projectdemo/business/cubit/createNetwork_state.dart';
import 'package:projectdemo/data/model/connectUsers_model.dart';
import 'package:projectdemo/services/p2p_service.dart';
import 'package:projectdemo/data/model/userProfile_model.dart';
import 'dart:async';

// Handles P2P network creation and connected user management
class CreateNetworkCubit extends Cubit<CreateNetworkState> {
  final P2PService? _p2pService;
  StreamSubscription? _memberSubscription;

  CreateNetworkCubit({P2PService? p2pService})
    : _p2pService = p2pService,
      super(CreateNetworkInitial());

  Future<void> startNetwork({
    required String networkName,
    required int maxConnections,
    required UserProfile currentUser,
  }) async {
    // Input Validation: network name
    if (networkName.trim().isEmpty) {
      emit(
        CreateNetworkError(
          message: 'Network name cannot be empty',
          previousState: state,
        ),
      );
      return;
    }

    // Input Validation: max connections
    if (maxConnections < 2) {
      emit(
        CreateNetworkError(
          message: 'Max connections can not be less than 2',
          previousState: state,
        ),
      );
      return;
    }

    emit(
      CreateNetworkStarting(
        networkName: networkName,
        maxConnections: maxConnections,
      ),
    );

    try {
      // Generate unique network ID
      final networkId = _generateNetworkId();

      // Create P2P network
      if (_p2pService != null) {
        await _p2pService.createNetwork(
          me: currentUser,
          name: networkName,
          max: maxConnections,
        );

        // Listen for member joins / leaves
        _memberSubscription = _p2pService.membersStream.listen(
          (members) {
            _updateConnectedUsers(members);
          },
          onError: (error) {
            emit(
              CreateNetworkError(
                message: 'Connection error: $error',
                previousState: state,
              ),
            );
          },
        );
      }

      // Create host user as first member
      final hostUser = ConnectedUser(
        id: currentUser.deviceId,
        name: currentUser.name,
        joinedAt: DateTime.now(),
      );

      emit(
        CreateNetworkActive(
          networkName: networkName,
          networkId: networkId,
          maxConnections: maxConnections,
          connectedUsers: [hostUser],
        ),
      );
    } catch (e) {
      emit(
        CreateNetworkError(
          message: 'Failed to create network: ${e.toString()}',
          previousState: CreateNetworkInitial(),
        ),
      );
    }
  }

  // Stops the active network and disconnects all users
  Future<void> stopNetwork() async {
    if (state is! CreateNetworkActive) return;

    try {
      // Stop P2P network
      if (_p2pService != null) {
        await _p2pService.stopNetwork();
      }

      await _memberSubscription?.cancel();
      _memberSubscription = null;

      emit(CreateNetworkInitial());
    } catch (e) {
      emit(
        CreateNetworkError(
          message: 'Failed to stop network: ${e.toString()}',
          previousState: state,
        ),
      );
    }
  }

  // Disconnects a specific user from the network
  Future<void> disconnectUser(String userId) async {
    if (state is! CreateNetworkActive) return;
    final currentState = state as CreateNetworkActive;

    try {
      // Send kick command via P2P service
      if (_p2pService != null) {
        _p2pService.kickUser(userId);
      }

      // Remove user from connected users list
      final updatedUsers = currentState.connectedUsers
          .where((user) => user.id != userId)
          .toList();

      emit(currentState.copyWith(connectedUsers: updatedUsers));
    } catch (e) {
      emit(
        CreateNetworkError(
          message: 'Failed to disconnect user: ${e.toString()}',
          previousState: currentState,
        ),
      );
    }
  }

  // Adds a new user to the connected users list
  void addUser(String userId, String userName) {
    if (state is! CreateNetworkActive) return;
    final currentState = state as CreateNetworkActive;

    if (currentState.isFull) {
      emit(
        CreateNetworkError(
          message: 'Network is full. Cannot accept more connections.',
          previousState: currentState,
        ),
      );
      return;
    }

    // Check if user already exists
    final exists = currentState.connectedUsers.any((user) => user.id == userId);
    if (exists) return;

    final newUser = ConnectedUser(
      id: userId,
      name: userName,
      joinedAt: DateTime.now(),
    );

    final updatedUsers = [...currentState.connectedUsers, newUser];
    emit(currentState.copyWith(connectedUsers: updatedUsers));
  }

  // Removes a user from the connected users list
  void removeUser(String userId) {
    if (state is! CreateNetworkActive) return;
    final currentState = state as CreateNetworkActive;

    final updatedUsers = currentState.connectedUsers
        .where((user) => user.id != userId)
        .toList();

    emit(currentState.copyWith(connectedUsers: updatedUsers));
  }

  // Recovers from error state back to previous state
  void clearError() {
    if (state is CreateNetworkError) {
      final errorState = state as CreateNetworkError;
      if (errorState.previousState != null) {
        emit(errorState.previousState!);
      } else {
        emit(CreateNetworkInitial());
      }
    }
  }

  // Generates a unique network ID
  String _generateNetworkId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final shortId = timestamp % 10000;
    return 'BEACON-$shortId';
  }

  // Updates connected users based on P2P service member list
  void _updateConnectedUsers(List<dynamic> members) {
    if (state is! CreateNetworkActive) return;

    final currentState = state as CreateNetworkActive;

    // This is a placeholder - actual implementation depends on P2PService API
    final users = members.map((member) {
      return ConnectedUser(
        id: member.deviceId ?? 'unknown',
        name: member.name ?? 'Unknown Device',
        joinedAt: DateTime.now(),
      );
    }).toList();

    emit(currentState.copyWith(connectedUsers: users));
  }

  // Cleanup method called when cubit is closed
  @override
  Future<void> close() async {
    await _memberSubscription?.cancel();

    if (state is CreateNetworkActive && _p2pService != null) {
      await _p2pService.stopNetwork();
    }

    return super.close();
  }
}
