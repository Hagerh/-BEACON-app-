import 'package:meta/meta.dart';
import 'package:projectdemo/data/model/deviceDetiles_model.dart';

@immutable
abstract class NetworkDashboardState {}

class NetworkDashboardLoading extends NetworkDashboardState {
  final String networkName;
  final int totalConnectors;
  NetworkDashboardLoading(this.networkName, this.totalConnectors);
}

class NetworkDashboardLoaded extends NetworkDashboardState {
  final String networkName;
  final int totalConnectors;
  final List<DeviceDetail> connectedDevices;

  NetworkDashboardLoaded({
    required this.networkName,
    required this.totalConnectors,
    required this.connectedDevices,
  });

  //for status updates
  NetworkDashboardLoaded updateDevice(String deviceId, {int? unread}) {
    final updatedList = connectedDevices.map((device) {
      if (device.deviceId == deviceId) {
        return device.copyWith(unread: unread); //new Cubit state with updated device 
      }
      return device;
    }).toList();

    return NetworkDashboardLoaded(
      networkName: networkName,
      totalConnectors: totalConnectors,
      connectedDevices: updatedList,
    );
  }
}

class NetworkDashboardError extends NetworkDashboardState {
  final String message;
  NetworkDashboardError(this.message);
}