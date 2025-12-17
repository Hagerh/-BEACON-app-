import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:projectdemo/core/services/p2p_service.dart';
import 'package:projectdemo/data/local/database_helper.dart';
import 'package:projectdemo/data/models/device_detail_model.dart';
import 'package:projectdemo/data/models/message_model.dart';
import 'package:projectdemo/business/cubit/network_dashboard_state.dart';

class NetworkDashboardCubit extends Cubit<NetworkDashboardState> {
  final P2PService p2pService;
  StreamSubscription<List<DeviceDetail>>? _membersSubscription;
  StreamSubscription<Message>? _messageSubscription;

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
      final db = DatabaseHelper.instance;

      // Try to resolve network id in local DB
      final network = await db.getNetworkByName(networkName);
      int? networkId = network == null ? null : network['network_id'] as int?;

      // If host and no network exists locally, create it and upsert host device
      if (networkId == null && p2pService.isHost && p2pService.currentUser != null) {
        try {
          networkId = await db.createNetwork(
            networkName: networkName,
            hostDeviceId: p2pService.currentUser!.deviceId,
          );

          // Ensure host device exists and is marked as host
          await db.upsertDevice(
            deviceId: p2pService.currentUser!.deviceId,
            networkId: networkId,
            name: p2pService.currentUser!.name,
            status: p2pService.currentUser!.status,
            isHost: 1,
            avatar: p2pService.currentUser!.avatarLetter,
            color: p2pService.currentUser!.avatarColor.value.toString(),
          );
        } catch (e) {
          // Log but continue — failure to persist shouldn't break the UI
          debugPrint('Failed to persist created network: $e');
        }
      }

      _membersSubscription = p2pService.membersStream.listen(
        (members) async {
          // Update device timestamps and upsert device info when we have a network id
          final db = DatabaseHelper.instance;

          if (networkId != null) {
            for (var member in members) {
              await db.updateDeviceLastSeen(member.deviceId);
              await db.upsertDevice(
                deviceId: member.deviceId,
                networkId: networkId,
                name: member.name,
                status: member.status,
                signalStrength: member.signalStrength,
                distance: member.distance,
                avatar: member.avatar,
                color: member.color.value.toString(),
              );
            }

            final devices = await db.getDevicesByNetworkId(networkId);

            emit(
              NetworkDashboardLoaded(
                networkName: networkName,
                isServer: p2pService.isHost,
                connectedDevices: devices,
                maxConnections: p2pService.maxMembers,
                networkId: networkId,
              ),
            );
          } else {
            // No local network record — just reflect current members
            for (var member in members) {
              await db.updateDeviceLastSeen(member.deviceId);
            }

            emit(
              NetworkDashboardLoaded(
                networkName: networkName,
                isServer: p2pService.isHost,
                connectedDevices: members,
                maxConnections: p2pService.maxMembers,
                networkId: null,
              ),
            );
          }
        },
        onError: (error) {
          emit(NetworkDashboardError('Connection lost: $error'));
        },
      );

      // Listen to incoming messages to refresh the device unread counts in UI
      _messageSubscription = p2pService.messagesStream.listen((message) async {
        try {
          final s = state;
          if (s is NetworkDashboardLoaded && s.networkId != null) {
            final db = DatabaseHelper.instance;
            // Refresh devices from DB which may have updated unread counts
            final devices = await db.getDevicesByNetworkId(s.networkId!);
            emit(s.copyWith(connectedDevices: devices));
          }
        } catch (_) {}
      });
    } catch (e) {
      emit(NetworkDashboardError('Failed to load dashboard: $e'));
    }
  }

  // Stop listening when leaving dashboard
  void stopListening() {
    _membersSubscription?.cancel();
    _membersSubscription = null;
    _messageSubscription?.cancel();
    _messageSubscription = null;
  }

  // Mark messages from a device as read
  void markDeviceMessagesAsRead(String deviceId) {
    if (state is NetworkDashboardLoaded) {
      final currentState = state as NetworkDashboardLoaded;
      emit(currentState.updateDevice(deviceId, unread: 0));
      // Persist unread reset in DB
      try {
        DatabaseHelper.instance.resetDeviceUnread(deviceId);
      } catch (_) {}
    }
  }

  // Broadcast a message to all members in the network
  Future<void> broadcastMessage(String message) async {
    try {
      // Persist broadcast message if we have a local network record and get id
      int? localId;
      try {
        final db = DatabaseHelper.instance;
        if (state is NetworkDashboardLoaded) {
          final s = state as NetworkDashboardLoaded;
          if (s.networkId != null) {
            final sender = p2pService.currentUser?.deviceId;
            localId = await db.insertMessage(
              networkId: s.networkId!,
              senderDeviceId: sender,
              receiverDeviceId: null,
              messageContent: message,
              isMine: true,
              isDelivered: true,
            );
          }
        }
      } catch (_) {}

      // Send broadcast including local message id when available
      p2pService.sendBroadcast(message, localMessageId: localId);
    } catch (e) {
      emit(NetworkDashboardError('Failed to broadcast: $e'));
    }
  }

  // Send a private message to a specific device
  Future<void> sendPrivateMessage(String deviceId, String message) async {
    try {
      int? localId;
      try {
        if (state is NetworkDashboardLoaded) {
          final s = state as NetworkDashboardLoaded;
          if (s.networkId != null) {
            final sender = p2pService.currentUser?.deviceId;
            final db = DatabaseHelper.instance;
            localId = await db.insertMessage(
              networkId: s.networkId!,
              senderDeviceId: sender,
              receiverDeviceId: deviceId,
              messageContent: message,
              isMine: true,
              isDelivered: false,
            );
          }
        }
      } catch (_) {}

      p2pService.sendPrivate(deviceId, message, localMessageId: localId);
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
      // If we were host, delete the network from local DB to clean up
      if (state is NetworkDashboardLoaded && (state as NetworkDashboardLoaded).isServer) {
        final s = state as NetworkDashboardLoaded;
        try {
          if (s.networkId != null && p2pService.currentUser != null) {
            await DatabaseHelper.instance.deleteNetwork(
              networkId: s.networkId!,
              requesterDeviceId: p2pService.currentUser!.deviceId,
            );
          }
        } catch (_) {}
      }
      stopListening();
      //todo: go back to discovery screen
    } catch (e) {
      emit(NetworkDashboardError('Failed to stop network: $e'));
    }
  }

  /// Update network name (host only). Persists to SQLite and updates Cubit state.
  /*Future<void> updateNetworkName(String newName) async {
    if (state is! NetworkDashboardLoaded) return;
    final current = state as NetworkDashboardLoaded;
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == current.networkName) return;

    try {
      final db = DatabaseHelper.instance;
      if (current.networkId != null) {
        await db.updateNetworkName(current.networkId!, trimmed);
      }

      emit(
        current.copyWith(networkName: trimmed),
      );
    } catch (e) {
      emit(NetworkDashboardError('Failed to update network name: $e'));
    }
  }*/
  Future<void> updateNetworkName(String newName) async {
    if (state is! NetworkDashboardLoaded) return;
    final current = state as NetworkDashboardLoaded;
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == current.networkName) return;

    // No DB, just update Cubit state
    emit(current.copyWith(networkName: trimmed));
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
    _messageSubscription?.cancel();
    return super.close();
  }
}
