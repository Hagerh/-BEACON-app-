import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projectdemo/business/cubit/networkDashboard_state.dart';
import 'package:projectdemo/constants/colors.dart';
import 'package:projectdemo/data/model/deviceDetail_model.dart';
import 'package:projectdemo/data/local/database_helper.dart';

class NetworkDashboardCubit extends Cubit<NetworkDashboardState> {
  NetworkDashboardCubit() : super(NetworkDashboardLoading('', 0));

  // loading the devices for a specific network
  Future<void> loadDevices(String networkName, int connectorCount) async {
    emit(NetworkDashboardLoading(networkName, connectorCount));
    try {
      final devices = await DatabaseHelper.instance.fetchDevicesForNetwork(networkName, connectorCount);
      emit(NetworkDashboardLoaded(
        networkName: networkName,
        totalConnectors: connectorCount,
        connectedDevices: devices,
      ));
    } catch (e) {
      emit(NetworkDashboardError(e.toString()));
    }
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
