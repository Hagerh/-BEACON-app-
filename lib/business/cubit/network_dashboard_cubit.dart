import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import 'package:projectdemo/core/services/p2p_service.dart';
import 'package:projectdemo/core/services/device_id_service.dart';
import 'package:projectdemo/data/local/database_helper.dart';
import 'package:projectdemo/data/models/device_detail_model.dart';
import 'package:projectdemo/business/cubit/network_dashboard_state.dart';

class NetworkDashboardCubit extends Cubit<NetworkDashboardState> {
  final P2PService p2pService;
  StreamSubscription<List<DeviceDetail>>? _membersSubscription;
  StreamSubscription? _messagesSubscription;

  NetworkDashboardCubit({required this.p2pService})
    : super(NetworkDashboardInitial());

  // Start listening to member updates from P2P service
  /*void startListening(String networkName) async {
    emit(NetworkDashboardLoading(networkName));

    try {
      // Get network ID from database
      final db = DatabaseHelper.instance;
      final networkId = await db.getNetworkIdByName(networkName);

      _membersSubscription = p2pService.membersStream.listen(
        (members) async {
          // Update device timestamps in database
          if (networkId != null) {
            for (var member in members) {
              await db.updateDeviceLastSeen(member.deviceId);
            }
          }

          emit(
            NetworkDashboardLoaded(
              networkName: networkName,
              isServer: p2pService.isHost, // .isServer to .isHost
              connectedDevices: members,
              maxConnections: p2pService.maxMembers,
              networkId: networkId,
            ),
          );
        },
        onError: (error) {
          emit(NetworkDashboardError('Connection lost: $error'));
        },
      );
    } catch (e) {
      emit(NetworkDashboardError('Failed to load dashboard: $e'));
    }
  }*/

  void startListening(String networkName) async {
    emit(NetworkDashboardLoading(networkName));

    try {
      _membersSubscription = p2pService.membersStream.listen(
        (members) async {
          // Update device timestamps (doesn't need networkId)
          final db = DatabaseHelper.instance;
          for (var member in members) {
            await db.updateDeviceLastSeen(member.deviceId);
          }

          emit(
            NetworkDashboardLoaded(
              networkName: networkName,
              isServer: p2pService.isHost,
              connectedDevices: members,
              maxConnections: p2pService.maxMembers,
              networkId: null, // or remove from state entirely
            ),
          );
        },
        onError: (error) {
          emit(NetworkDashboardError('Connection lost: $error'));
        },
      );

      // Listen to incoming messages
      _messagesSubscription = p2pService.messagesStream.listen(
        (message) {
          debugPrint('📨 Received message: ${message.text}');
          // In a real app, you'd update the state to show this message or increment unread count
          // For now, just log it to verify messages are working
        },
        onError: (error) {
          debugPrint('❌ Message stream error: $error');
        },
      );
    } catch (e) {
      emit(NetworkDashboardError('Failed to load dashboard: $e'));
    }
  }

  // Stop listening when leaving dashboard
  void stopListening() {
    _membersSubscription?.cancel();
    _membersSubscription = null;
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
  }

  // Mark messages from a device as read
  void markDeviceMessagesAsRead(String deviceId) {
    if (state is NetworkDashboardLoaded) {
      final currentState = state as NetworkDashboardLoaded;
      emit(currentState.updateDevice(deviceId, unread: 0));
    }
  }

  // Broadcast a message to all members in the network
  void broadcastMessage(String message) {
    try {
      p2pService.sendBroadcast(message);
    } catch (e) {
      emit(NetworkDashboardError('Failed to broadcast: $e'));
    }
  }

  // Send a private message to a specific device
  void sendPrivateMessage(String deviceId, String message) {
    try {
      p2pService.sendPrivate(deviceId, message);
    } catch (e) {
      emit(NetworkDashboardError('Failed to send message: $e'));
    }
  }

  // Kick a user from the network (server)
  void kickUser(String deviceId) {
    try {
      p2pService.kickUser(deviceId);
      // Member will be removed automatically removed via streamClientList
      //?stopListening();
      //todo: go back to discovery screen
    } catch (e) {
      emit(NetworkDashboardError('Failed to kick user: $e'));
    }
  }

  // Leave the network (client)
  Future<void> leaveNetwork() async {
    try {
      // Get current device ID for database cleanup
      final deviceId = await DeviceIdService.getDeviceId();
      final db = DatabaseHelper.instance;

      // Leave the P2P network
      await p2pService.leaveNetwork();

      // Clean up database - delete device (this will cascade if it's a host)
      await db.deleteDevice(deviceId);

      stopListening();
    } catch (e) {
      emit(NetworkDashboardError('Failed to leave network: $e'));
    }
  }

  // Stop the network (server/host only)
  Future<void> stopNetwork() async {
    if (state is! NetworkDashboardLoaded) return;
    final current = state as NetworkDashboardLoaded;

    // Only allow host to stop network
    if (!current.isServer) {
      emit(NetworkDashboardError('Only the host can stop the network'));
      return;
    }

    try {
      // Get current device ID for database cleanup
      final deviceId = await DeviceIdService.getDeviceId();
      final db = DatabaseHelper.instance;

      // Stop the P2P network
      await p2pService.stopNetwork();

      // Clean up database - delete device (which will cascade delete network if host)
      await db.deleteDevice(deviceId);

      stopListening();

      //go back to landing screen
      //Navigator.pushReplacementNamed(context, landingScreen);
    } catch (e) {
      emit(NetworkDashboardError('Failed to stop network: $e'));
    }
  }

  /// Update network name (host only). Persists to SQLite and updates Cubit state.
  Future<void> updateNetworkName(String newName) async {
    if (state is! NetworkDashboardLoaded) return;
    final current = state as NetworkDashboardLoaded;
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == current.networkName) return;

    // Host only
    if (!current.isServer) return;

    // No DB, just update Cubit state
    emit(current.copyWith(networkName: trimmed));
  }

  /// Update max connections limit for this network (host only).
  /// This is enforced at the P2P layer (see P2PService) and reflected in UI.
  /// Validates that max cannot be less than current number of connected devices.
  void updateMaxConnections(int max) {
    if (state is! NetworkDashboardLoaded) return;
    final current = state as NetworkDashboardLoaded;

    // Host only
    if (!current.isServer) return;

    // Validation
    if (max <= 2) {
      emit(NetworkDashboardError('Max connections must be greater than 2'));
      return;
    }

    // Cannot be less than current number of connected devices
    final currentConnections = current.connectedDevices.length;
    if (max < currentConnections) {
      emit(
        NetworkDashboardError(
          'Cannot be less than the current connections ($currentConnections).',
        ),
      );
      return;
    }

    // Update P2P service and state
    p2pService.updateMaxMembers(max);
    emit(current.copyWith(maxConnections: max));
  }

  @override
  Future<void> close() {
    _membersSubscription?.cancel();
    _messagesSubscription?.cancel();
    return super.close();
  }
}
