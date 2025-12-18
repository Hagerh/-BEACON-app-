import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';

import 'package:projectdemo/core/services/p2p_service.dart';
import 'package:projectdemo/data/models/user_profile_model.dart';
import 'package:projectdemo/business/cubit/network_discovery_state.dart';
import 'package:flutter/foundation.dart';


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
      emit(NetworkConnecting(device: device));

      // Connect to the selected device
      await p2pService.connectToServer(device);

      emit(NetworkConnected(device: device));
    } catch (e) {
      emit(NetworkError('Failed to connect: $e'));
    }
  }

  @override
  Future<void> close() {
    // Cancel all subscriptions on close
    _discoverySubscription?.cancel();
    return super.close();
  }
}
