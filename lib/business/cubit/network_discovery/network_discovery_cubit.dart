import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import 'package:projectdemo/business/cubit/network_discovery/network_discovery_state.dart';

import 'package:projectdemo/core/services/p2p_service.dart';
import 'package:projectdemo/data/models/user_profile_model.dart';
import 'package:projectdemo/data/local/database_helper.dart';

class NetworkCubit extends Cubit<NetworkState> {
  final P2PService p2pService;
  StreamSubscription? _discoverySubscription;

  NetworkCubit({required this.p2pService}) : super(NetworkInitial());

  Future<void> startDiscovery(UserProfile currentUser) async {
    emit(NetworkLoading());

    try {
      await p2pService.initializeClient(currentUser);

      _discoverySubscription = p2pService.discoveryStream.listen(
        (devices) {
          emit(NetworkLoaded(networks: devices));
        },
        onError: (error) {
          emit(NetworkError(error.toString()));
        },
      );

      await p2pService.startDiscovery();
    } catch (e) {
      emit(NetworkError('Failed to start discovery: $e'));
    }
  }

  Future<void> stopDiscovery() async {
    try {
      await p2pService.stopDiscovery();
      await _discoverySubscription?.cancel();
      _discoverySubscription = null;
    } catch (e) {
      emit(NetworkError('Failed to stop discovery: $e'));
    }
  }

  Future<void> connectToNetwork(BleDiscoveredDevice device) async {
    try {
      emit(NetworkConnecting(device: device));

      await p2pService.connectToServer(device);

      // FIX: Identify self to the network immediately upon connection
      p2pService.sendHandshake();

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

        await db.upsertDevice(
          deviceId: device.deviceAddress,
          networkId: networkId,
          name: device.deviceName,
          status: 'Active',
          isHost: 1,
        );
      } catch (e) {
        // ignore: avoid_print
        print('Warning: failed to ensure network/device in local DB: $e');
      }

      emit(NetworkConnected(device: device));
    } catch (e) {
      emit(NetworkError('Failed to connect: $e'));
    }
  }

  @override
  Future<void> close() {
    _discoverySubscription?.cancel();
    return super.close();
  }
}