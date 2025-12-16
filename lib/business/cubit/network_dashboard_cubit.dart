import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:projectdemo/core/services/p2p_service.dart';
import 'package:projectdemo/data/local/database_helper.dart';
import 'package:projectdemo/data/models/device_detail_model.dart';
import 'package:projectdemo/business/cubit/network_dashboard_state.dart';

class NetworkDashboardCubit extends Cubit<NetworkDashboardState> {
  final P2PService p2pService;
  StreamSubscription<List<DeviceDetail>>? _membersSubscription;

  NetworkDashboardCubit({required this.p2pService})
    : super(NetworkDashboardInitial());

  // Start listening to member updates from P2P service
  void startListening(String networkName) async {
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
              isServer: p2pService.isHost,
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
  }

  // Stop listening when leaving dashboard
  void stopListening() {
    _membersSubscription?.cancel();
    _membersSubscription = null;
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
      await p2pService.leaveNetwork();
      stopListening();
      //todo: go back to discovery screen
    } catch (e) {
      emit(NetworkDashboardError('Failed to leave network: $e'));
    }
  }

  // Stop the network (server)
  Future<void> stopNetwork() async {
    try {
      await p2pService.stopNetwork();
      stopListening();
      //todo: go back to discovery screen
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

    try {
      final db = DatabaseHelper.instance;
      if (current.networkId != null) {
        await db.updateNetworkName(current.networkId!, trimmed);
      }

      emit(current.copyWith(networkName: trimmed));
    } catch (e) {
      emit(NetworkDashboardError('Failed to update network name: $e'));
    }
  }

  /// Update max connections limit for this network (host only).
  /// This is enforced at the P2P layer (see P2PService) and reflected in UI.
  void updateMaxConnections(int max) {
    if (state is! NetworkDashboardLoaded) return;
    if (max <= 0) return;

    final current = state as NetworkDashboardLoaded;

    // Host role is fixed for the life of this network; we only allow host
    // to tweak this in-memory/app-level limit.
    if (!current.isServer) return;

    p2pService.updateMaxMembers(max);
    emit(current.copyWith(maxConnections: max));
  }

  @override
  Future<void> close() {
    _membersSubscription?.cancel();
    return super.close();
  }
}
