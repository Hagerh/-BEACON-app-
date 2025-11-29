
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projectdemo/business/cubit/network_state.dart';
import 'package:projectdemo/data/local/database_helper.dart';

class NetworkCubit extends Cubit<NetworkState> {
  NetworkCubit() : super(NetworkInitial()); // Initial state

  // Simulates fetching initial network data
  Future<void> loadNetworks() async {
    
     emit(NetworkLoading());
    try {
      // fetch from local sqlite
      final networks = await DatabaseHelper.instance.fetchNetworkSummaries();
      emit(NetworkLoaded(networks: networks));
    } catch (e) {
      emit(NetworkError(e.toString()));
    }
  }

  // Simulates refreshing the network list
  Future<void> refreshNetworks() async {
    // Only proceed if current state is NetworkLoaded
    if (state is NetworkLoaded) {
      final currentState = state as NetworkLoaded;
      
      emit(currentState.copyWith(isRefreshing: true));
      try {
        final networks = await DatabaseHelper.instance.fetchNetworkSummaries();
        emit(NetworkLoaded(networks: networks, isRefreshing: false));
      } catch (e) {
        emit(NetworkError(e.toString()));
      }
    }
  }
}
