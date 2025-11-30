import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projectdemo/core/services/p2p_service.dart';
import 'package:projectdemo/data/models/device_detail_model.dart';
import 'package:projectdemo/business/cubit/network_dashboard_state.dart';

class NetworkDashboardCubit extends Cubit<NetworkDashboardState> {
  final P2PService p2pService;
  StreamSubscription<List<DeviceDetail>>? _membersSubscription;

  NetworkDashboardCubit({required this.p2pService})
    : super(NetworkDashboardInitial());

  // Start listening to member updates from P2P service
  void startListening(String networkName) {
    emit(NetworkDashboardLoading(networkName));

    try {
      _membersSubscription = p2pService.membersStream.listen(
        (members) {
          emit(
            NetworkDashboardLoaded(
              networkName: networkName,
              isServer: p2pService.isServer,
              connectedDevices: members,
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

  @override
  Future<void> close() {
    _membersSubscription?.cancel();
    return super.close();
  }
}
