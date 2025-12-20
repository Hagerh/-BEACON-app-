import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:projectdemo/core/services/p2p_service.dart';
import 'package:projectdemo/core/services/device_id_service.dart';
import 'package:projectdemo/data/local/database_helper.dart';
import 'package:projectdemo/data/models/device_detail_model.dart';
import 'package:projectdemo/business/cubit/network_dashboard/network_dashboard_state.dart';

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
      final db = DatabaseHelper.instance;

      // Try to resolve network id in local DB
      final network = await db.getNetworkByName(networkName);
      int? networkId = network == null ? null : network['network_id'] as int?;

      // If no network exists locally, create a local record so that messages
      // can be persisted on this device as well (host and clients).
      if (networkId == null && p2pService.currentUser != null) {
        try {
          networkId = await db.createNetwork(
            networkName: networkName,
            hostDeviceId: p2pService.currentUser!.deviceId,
          );

          // Ensure *this* device exists in the local DB.
          await db.upsertDevice(
            deviceId: p2pService.currentUser!.deviceId,
            networkId: networkId,
            name: p2pService.currentUser!.name,
            status: p2pService.currentUser!.status,
            isHost: p2pService.isHost ? 1 : 0,
            avatar: p2pService.currentUser!.avatarLetter,
            color: p2pService.currentUser!.avatarColor.value.toString(),
          );
        } catch (e) {
          // Log but continue — failure to persist shouldn't break the UI
          debugPrint('Failed to persist created network (local mirror): $e');
        }
      }

      // Broadcast profile to all peers when joining network
      p2pService.broadcastProfile();

      // If we already have members, emit initial state immediately
      if (p2pService.members.isNotEmpty) {
        emit(
          NetworkDashboardLoaded(
            networkName: networkName,
            isServer: p2pService.isHost,
            connectedDevices: p2pService.members,
            maxConnections: p2pService.maxMembers,
            networkId: networkId,
          ),
        );
      }

      _membersSubscription = p2pService.membersStream.listen(
        (members) async {
          // Check for disconnection (if service has cleared state)
          if (p2pService.currentUser == null) {
            await leaveNetwork();
            return;
          }

          final db = DatabaseHelper.instance;

          if (networkId != null) {
            for (var member in members) {
              // Always update timestamps
              await db.updateDeviceLastSeen(member.deviceId);
            }

            // Check if other properties have changed
            final currentState = state;
            bool hasChanges = false;
            if (currentState is NetworkDashboardLoaded) {
              final currentDevices = currentState.connectedDevices
                  .map((d) => d.deviceId)
                  .toSet();
              final newDevices = members.map((d) => d.deviceId).toSet();

              // Check if device list changed
              if (currentDevices.length != newDevices.length ||
                  !currentDevices.containsAll(newDevices)) {
                hasChanges = true;
              } else {
                // Check if any device properties changed
                for (var member in members) {
                  try {
                    final currentDevice = currentState.connectedDevices
                        .firstWhere((d) => d.deviceId == member.deviceId);
                    if (currentDevice.status != member.status ||
                        currentDevice.name != member.name ||
                        currentDevice.signalStrength != member.signalStrength ||
                        currentDevice.distance != member.distance) {
                      hasChanges = true;
                      break;
                    }
                  } catch (e) {
                    // Device not found in current state, treat as change
                    hasChanges = true;
                    break;
                  }
                }
              }
            } else {
              // No current state, treat as change
              hasChanges = true;
            }

            // Only do expensive upserts if properties changed
            if (hasChanges) {
              for (var member in members) {
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
            }

            // Always read from DB to get updated timestamps
            final devices = await db.getDevicesByNetworkId(networkId);

            // Only emit if state actually changed
            // Reuse currentState from earlier check (state won't change in same function)
            if (currentState is! NetworkDashboardLoaded) {
              // No current state, emit new state
              emit(
                NetworkDashboardLoaded(
                  networkName: networkName,
                  isServer: p2pService.isHost,
                  connectedDevices: devices, // Includes updated timestamps
                  maxConnections: p2pService.maxMembers,
                  networkId: networkId,
                ),
              );
            } else if (currentState.connectedDevices.length != devices.length ||
                !DeviceDetail.areListsEqual(
                  currentState.connectedDevices,
                  devices,
                )) {
              // State exists but devices changed, emit updated state
              emit(
                NetworkDashboardLoaded(
                  networkName: networkName,
                  isServer: p2pService.isHost,
                  connectedDevices: devices, // Includes updated timestamps
                  maxConnections: p2pService.maxMembers,
                  networkId: networkId,
                ),
              );
            }
            // If state unchanged, skip emit (timestamps updated in DB but UI won't refresh)
          } else {
            // No local network record — just reflect current members
            // Always update timestamps even without networkId
            for (var member in members) {
              await db.updateDeviceLastSeen(member.deviceId);
            }

            // Check if we need to emit new state
            final currentState = state;
            if (currentState is! NetworkDashboardLoaded) {
              emit(
                NetworkDashboardLoaded(
                  networkName: networkName,
                  isServer: p2pService.isHost,
                  connectedDevices: members,
                  maxConnections: p2pService.maxMembers,
                  networkId: null,
                ),
              );
            } else {
              final currentIds = currentState.connectedDevices
                  .map((d) => d.deviceId)
                  .toSet();
              final newIds = members.map((m) => m.deviceId).toSet();

              // Only emit if device list changed
              if (currentIds.length != newIds.length ||
                  !currentIds.containsAll(newIds)) {
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
            }
          }
        },
        onError: (error) {
          emit(NetworkDashboardError('Connection lost: $error'));
        },
      );

      // Listen to incoming messages; refresh device unread counts and log
      _messagesSubscription = p2pService.messagesStream.listen(
        (message) async {
          debugPrint('📨 Received message: ${message.text}');
          try {
            final s = state;
            if (s is NetworkDashboardLoaded && s.networkId != null) {
              final db = DatabaseHelper.instance;
              // Refresh devices from DB which may have updated unread counts
              final devices = await db.getDevicesByNetworkId(s.networkId!);
              emit(s.copyWith(connectedDevices: devices));
            }
          } catch (_) {}
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
      // Persist unread reset in DB
      try {
        DatabaseHelper.instance.resetDeviceUnread(deviceId);
      } catch (_) {}
    }
  }

  // Broadcast a message to all members in the network
  Future<void> broadcastMessage(String message) async {
    try {
      // Persist broadcast message if we have a local network record
      try {
        final db = DatabaseHelper.instance;
        if (state is NetworkDashboardLoaded) {
          final s = state as NetworkDashboardLoaded;
          if (s.networkId != null) {
            final sender = p2pService.currentUser?.deviceId;
            await db.insertMessage(
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

      // Send broadcast
      p2pService.sendBroadcast(message);
    } catch (e) {
      emit(NetworkDashboardError('Failed to broadcast: $e'));
    }
  }

  // Send a private message to a specific device
  Future<void> sendPrivateMessage(String deviceId, String message) async {
    try {
      // Persist message if we have a local network record
      try {
        if (state is NetworkDashboardLoaded) {
          final s = state as NetworkDashboardLoaded;
          if (s.networkId != null) {
            final sender = p2pService.currentUser?.deviceId;
            final db = DatabaseHelper.instance;
            await db.insertMessage(
              networkId: s.networkId!,
              senderDeviceId: sender,
              receiverDeviceId: deviceId,
              messageContent: message,
              isMine: true,
              isDelivered: true, // Delivered immediately in P2P
            );
          }
        }
      } catch (_) {}

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
      stopListening();

      // Get current device ID for database cleanup
      final deviceId = await DeviceIdService.getDeviceId();
      final db = DatabaseHelper.instance;

      // Leave the P2P network
      await p2pService.leaveNetwork();

      // Clean up database - delete device (this will cascade if it's a host)
      await db.deleteDevice(deviceId);

      emit(NetworkDashboardDisconnected(isServer: false));
    } catch (e) {
      emit(NetworkDashboardError('Failed to leave network: $e'));
    }
  }

  // Stop the network (server/host only)
  Future<void> stopNetwork() async {
    if (state is! NetworkDashboardLoaded) return;
    final current = state as NetworkDashboardLoaded;

    // Host only
    if (!current.isServer) return;

    try {
      stopListening();

      emit(NetworkDashboardDisconnected(isServer: true));

      // Stop the P2P network
      await p2pService.stopNetwork();

      // If we were host, delete the network from local DB to clean up
      if (current.isServer &&
          current.networkId != null &&
          p2pService.currentUser != null) {
        try {
          await DatabaseHelper.instance.deleteNetwork(
            networkId: current.networkId!,
            requesterDeviceId: p2pService.currentUser!.deviceId,
          );
        } catch (_) {}
      }
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
    if (max < 2) {
      emit(NetworkDashboardError('Max connections must at least be 2.'));
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

  /// Add a mock device for testing (debug only)
  void addMockDevice() {
    p2pService.addMockDevice(
      name: 'Test Device ${DateTime.now().second}',
      signalStrength: 75,
      distance: '10m',
    );
  }

  @override
  Future<void> close() {
    _membersSubscription?.cancel();
    _messagesSubscription?.cancel();
    return super.close();
  }
}
