
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projectdemo/business/cubit/networkDashboard_state.dart';
import 'package:projectdemo/constants/colors.dart';
import 'package:projectdemo/data/model/deviceDetiles_model.dart';

class NetworkDashboardCubit extends Cubit<NetworkDashboardState> {
  NetworkDashboardCubit() : super(NetworkDashboardLoading('', 0));

  // loading the devices for a specific network
  void loadDevices(String networkName, int connectorCount) {
    emit(NetworkDashboardLoading(networkName, connectorCount));

    // TODO: Replace with real P2P discovery
    final allDevices = [
      DeviceDetail(
        name: 'Sarah Mitchell',
        deviceId: 'Device #A123',
        status: 'Active',
        unread: 2,
        signalStrength: 85,
        distance: '50m',
        avatar: 'S',
        color: AppColors.beaconOrange,
      ),
      DeviceDetail(
        name: 'John Parker',
        deviceId: 'Device #B456',
        status: 'Active',
        unread: 0,
        signalStrength: 92,
        distance: '30m',
        avatar: 'J',
        color: AppColors.connectionTeal,
      ),
      DeviceDetail(
        name: 'Emily Chen',
        deviceId: 'Device #C789',
        status: 'Idle',
        unread: 1,
        signalStrength: 68,
        distance: '120m',
        avatar: 'E',
        color: AppColors.infoBlue,
      ),
      DeviceDetail(
        name: 'Michael Brown',
        deviceId: 'Device #D012',
        status: 'Active',
        unread: 0,
        signalStrength: 78,
        distance: '80m',
        avatar: 'M',
        color: AppColors.beaconOrange,
      ),
      DeviceDetail(
        name: 'Lisa Anderson',
        deviceId: 'Device #E345',
        status: 'Away',
        unread: 4,
        signalStrength: 55,
        distance: '150m',
        avatar: 'L',
        color: AppColors.infoBlue,
      ),
    ];

    final connectedDevices = allDevices.take(connectorCount).toList();

    emit(NetworkDashboardLoaded(
      networkName: networkName,
      totalConnectors: connectorCount,
      connectedDevices: connectedDevices,
    ));
  }

  // to mark unread messages -->  read when opening chat
  void markDeviceMessagesAsRead(String deviceId) {
    if (state is NetworkDashboardLoaded) {
      final currentState = state as NetworkDashboardLoaded;
      emit(currentState.updateDevice(deviceId, unread: 0));
    }
  }

  void broadcastMessage(String message) {
    // TODO: Implement P2P broadcast  logic
    // For now, it just shows a success message via the UI
    print('Broadcasting: $message');
  }
}