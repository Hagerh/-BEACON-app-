// Create P2P network as host
// Manage connected users (add/remove)
// Handle network stop
// Integrate with P2PService

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projectdemo/core/constants/colors.dart';
import 'package:projectdemo/core/services/p2p_service.dart';
import 'package:projectdemo/core/services/device_id_service.dart';
import 'package:projectdemo/data/local/database_helper.dart';
import 'package:projectdemo/data/models/connected_users_model.dart';
import 'package:projectdemo/data/models/user_profile_model.dart';
import 'package:projectdemo/business/cubit/create_network_state.dart';

// Handles P2P network creation and connected user management
class CreateNetworkCubit extends Cubit<CreateNetworkState> {
  final P2PService _p2pService;
  StreamSubscription? _memberSubscription;

  CreateNetworkCubit({required P2PService p2pService})
    : _p2pService = p2pService,
      super(CreateNetworkInitial());

  Future<void> startNetwork({
    required String networkName,
    required int maxConnections,
  }) async {
    if (networkName.trim().isEmpty) {
      emit(
        CreateNetworkError(
          message: 'Network name cannot be empty',
          previousState: state,
        ),
      );
      return;
    }

    if (maxConnections < 2) {
      emit(
        CreateNetworkError(
          message: 'Max connections can not be less than 2',
          previousState: state,
        ),
      );
      return;
    }
    // validated
    emit(
      CreateNetworkStarting(
        networkName: networkName,
        maxConnections: maxConnections,
      ),
    );

    try {
      // Get current user profile from database
      final currentUser = await _getCurrentUserProfile();

      // Create P2P network
      await _p2pService.initializeServer(currentUser);
      await _p2pService.createNetwork(name: networkName, max: maxConnections);

      // Save network to database
      final db = DatabaseHelper.instance;
      final networkId = await db.saveNetwork(
        networkName: networkName,
        hostDeviceId: currentUser.deviceId,
        status: 'Active',
      );

      // Save host device to database
      await db.upsertDevice(
        deviceId: currentUser.deviceId,
        networkId: networkId,
        name: currentUser.name,
        status: 'Active',
        avatar: currentUser.avatarLetter,
        color:
            '#${currentUser.avatarColor.value.toRadixString(16).padLeft(8, '0')}',
        isHost: true,
      );

      // Listen for member joins / leaves
      _memberSubscription = _p2pService.membersStream.listen(
        (members) {
          _updateConnectedUsers(members, networkId);
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

      // Create host user as first member
      final hostUser = ConnectedUser(
        id: currentUser.deviceId,
        name: currentUser.name,
        joinedAt: DateTime.now(),
      );

      emit(
        CreateNetworkActive(
          networkName: networkName,
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

    final currentState = state as CreateNetworkActive;

    try {
      // Update network status in database
      final db = DatabaseHelper.instance;
      final networkId = await db.getNetworkIdByName(currentState.networkName);

      if (networkId != null) {
        await db.updateNetworkStatus(networkId, 'Inactive');
        await db.markNetworkDevicesOffline(networkId);
      }

      // Stop P2P network
      await _p2pService.stopNetwork();

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
      _p2pService.kickUser(userId);

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

  /// Gets the current user profile from database or creates a default one
  /// Uses persistent device ID that remains the same across app sessions
  Future<UserProfile> _getCurrentUserProfile() async {
    final db = DatabaseHelper.instance;

    // Get persistent device ID
    final deviceId = await DeviceIdService.getDeviceId();

    // Try to load existing user profile from database
    UserProfile? user = await db.getUserProfile(deviceId);

    // If not found, create a default profile
    if (user == null) {
      user = UserProfile(
        emergencyContact: '',
        name: 'My Device',
        deviceId: deviceId,
        avatarLetter: 'M',
        avatarColor: AppColors.connectionTeal,
        status: 'Active',
        email: '',
        phone: '',
        address: '',
        bloodType: '',
      );

      // Save the new profile to database for future use
      await db.saveUserProfile(user);
    }

    return user;
  }

  // Updates connected users based on P2P service member list
  void _updateConnectedUsers(List<dynamic> members, int networkId) async {
    if (state is! CreateNetworkActive) return;

    final currentState = state as CreateNetworkActive;
    final db = DatabaseHelper.instance;

    // Update database for each member
    for (var member in members) {
      final deviceId = member.deviceId ?? 'unknown';
      final name = member.name ?? 'Unknown Device';

      await db.upsertDevice(
        deviceId: deviceId,
        networkId: networkId,
        name: name,
        status: 'Active',
        avatar: name.isNotEmpty ? name[0] : '?',
        isHost: member.isHost ?? false,
      );
    }

    // Convert to ConnectedUser list
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

    if (state is CreateNetworkActive) {
      await _p2pService.stopNetwork();
    }

    return super.close();
  }
}
