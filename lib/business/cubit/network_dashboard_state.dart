import 'package:flutter/foundation.dart';
import 'package:projectdemo/data/models/device_detail_model.dart';

@immutable
abstract class NetworkDashboardState {}

class NetworkDashboardInitial extends NetworkDashboardState {}

class NetworkDashboardLoading extends NetworkDashboardState {
  final String networkName;
  NetworkDashboardLoading(this.networkName);
}

class NetworkDashboardLoaded extends NetworkDashboardState {
  final String networkName;
  final bool isServer;
  final List<DeviceDetail> connectedDevices;
  final int? maxConnections;
  final int? networkId;

  NetworkDashboardLoaded({
    required this.networkName,
    required this.isServer,
    required this.connectedDevices,
    this.maxConnections,
    this.networkId,
  });

  NetworkDashboardLoaded updateDevice(String deviceId, {int? unread}) {
    final updatedList = connectedDevices.map((device) {
      if (device.deviceId == deviceId) {
        return device.copyWith(
          unread: unread,
        ); //new Cubit state with updated device
      }
      return device;
    }).toList();

    return NetworkDashboardLoaded(
      networkName: networkName,
      isServer: isServer,
      connectedDevices: updatedList,
      maxConnections: maxConnections,
      networkId: networkId,
    );
  }

  NetworkDashboardLoaded copyWith({
    String? networkName,
    bool? isServer,
    List<DeviceDetail>? connectedDevices,
    int? maxConnections,
    int? networkId,
  }) {
    return NetworkDashboardLoaded(
      networkName: networkName ?? this.networkName,
      isServer: isServer ?? this.isServer,
      connectedDevices: connectedDevices ?? this.connectedDevices,
      maxConnections: maxConnections ?? this.maxConnections,
      networkId: networkId ?? this.networkId,
    );
  }
}

class NetworkDashboardError extends NetworkDashboardState {
  final String message;
  NetworkDashboardError(this.message);
}
