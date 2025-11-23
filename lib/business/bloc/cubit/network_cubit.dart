
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projectdemo/data/model/device_model.dart';
import 'package:projectdemo/business/bloc/cubit/network_state.dart';

class NetworkCubit extends Cubit<NetworkState> {
  NetworkCubit() : super(NetworkInitial()); // Initial state

  // Simulates fetching initial network data
  Future<void> loadNetworks() async {
    
     emit(NetworkLoading());

    // Delay to simulate network/p2p discovery time
    await Future.delayed(const Duration(milliseconds: 500)); 

    // TODO: Replace with real peer-to-peer  logic 
    final List<Device> initialNetworks = [
      Device(
        id: "Emergency hub 01",
        status: "Connected",
        lastSeen: "2 mins ago",
        connectors: 1,
      ),
      Device(
        id: "Available Network 02",
        status: "Available",
        lastSeen: "5 mins ago",
        connectors: 3,
      ),
    ];
    
    emit(NetworkLoaded(networks: initialNetworks));
  }

  // Simulates refreshing the network list
  Future<void> refreshNetworks() async {
    // Only proceed if current state is NetworkLoaded
    if (state is NetworkLoaded) {
      final currentState = state as NetworkLoaded;
      
      emit(currentState.copyWith(isRefreshing: true));

      
      await Future.delayed(const Duration(seconds: 2));

      // TODO: Replace with real peer-to-peer  logic 
      final List<Device> refreshedNetworks = [
        Device(
          id: "Emergency hub 01",
          status: "Connected",
          lastSeen: "just now",
          connectors: 1,
        ),
        Device(
          id: "Available Network 03",
          status: "Available",
          lastSeen: "10 seconds ago",
          connectors: 2,
        ),
        // A new device appears
        Device(
          id: "New Device Found 04",
          status: "Available",
          lastSeen: "just now",
          connectors: 5,
        ),
      ];
      
      // Emit the final loaded state with isRefreshing set to false
      emit(NetworkLoaded(networks: refreshedNetworks, isRefreshing: false));
    }
  }
}