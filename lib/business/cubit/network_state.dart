import 'package:flutter/foundation.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';

@immutable
abstract class NetworkState {}

class NetworkInitial extends NetworkState {}

class NetworkLoading extends NetworkState {}

class NetworkLoaded extends NetworkState {
  final List<BleDiscoveredDevice> networks;
  NetworkLoaded({required this.networks});
}

class NetworkConnecting extends NetworkState {
  final BleDiscoveredDevice device;
  NetworkConnecting({required this.device});
}

class NetworkConnected extends NetworkState {
  final BleDiscoveredDevice device;
  NetworkConnected({required this.device});
}

class NetworkError extends NetworkState {
  final String message;
  NetworkError(this.message);
}
