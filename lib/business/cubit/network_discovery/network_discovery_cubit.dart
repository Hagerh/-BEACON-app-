import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';

import 'package:projectdemo/core/services/p2p_service.dart';
import 'package:projectdemo/data/models/user_profile_model.dart';
import 'package:projectdemo/business/cubit/network_discovery/network_discovery_state.dart';
import 'package:projectdemo/data/local/database_helper.dart';

class NetworkCubit extends Cubit<NetworkState> {
  final P2PService p2pService;
  StreamSubscription? _discoverySubscription;

  NetworkCubit({required this.p2pService}) : super(NetworkInitial());

  Future<void> startDiscovery(UserProfile currentUser) async {
    emit(NetworkLoading());

    try {
      // Initialize the client with the current user profile
      await p2pService.initializeClient(currentUser);

      // Listen to discovery stream
      _discoverySubscription = p2pService.discoveryStream.listen(
        (devices) {
          emit(NetworkLoaded(networks: devices));
        },
        onError: (error) {
          emit(NetworkError(error.toString()));
        },
      );

      // Start discovery
      await p2pService.startDiscovery();
    } catch (e) {
      emit(NetworkError('Failed to start discovery: $e'));
    }
  }

  Future<void> stopDiscovery() async {
    try {
      // Stop discovery
      await p2pService.stopDiscovery();

      // Cancel subscription
      await _discoverySubscription?.cancel();
      _discoverySubscription = null;
    } catch (e) {
      emit(NetworkError('Failed to stop discovery: $e'));
    }
  }

  Future<void> connectToNetwork(BleDiscoveredDevice device) async {
    try {
      if (isClosed) return; // Don't start if already closed
      emit(NetworkConnecting(device: device));

      // Connect to the selected device
      await p2pService.connectToServer(device);

      // Ensure we have a local network record for this server so incoming messages can be persisted
      try {
        final db = DatabaseHelper.instance;
        final existing = await db.getNetworkByName(device.deviceName);
        int networkId;
        if (existing == null) {
          networkId = await db.createNetwork(
            networkName: device.deviceName,
            hostDeviceId: device.deviceAddress,
          );
        } else {
          networkId = existing['network_id'] as int;
        }

        // Upsert the host device entry locally (mark as host)
        await db.upsertDevice(
          deviceId: device.deviceAddress,
          networkId: networkId,
          name: device.deviceName,
          status: 'Active',
          isHost: 1,
        );
      } catch (e) {
        // Swallow DB errors to avoid breaking connect flow; still helpful to log
        // ignore: avoid_print
        print('Warning: failed to ensure network/device in local DB: $e');
      }

      // Check if cubit is still open before emitting
      if (!isClosed) {
        emit(NetworkConnected(device: device));
      }
    } catch (e) {
      // Check if cubit is still open before emitting error
      if (!isClosed) {
        emit(NetworkError('Failed to connect: $e'));
      }
    }
  }

  @override
  Future<void> close() {
    // Cancel all subscriptions on close
    _discoverySubscription?.cancel();
    return super.close();
  }
}
