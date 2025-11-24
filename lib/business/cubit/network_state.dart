
import 'package:flutter/material.dart';
import 'package:projectdemo/data/model/device_model.dart';

//this is the state file for NetworkCubit that manages network-related states
@immutable
abstract class NetworkState {}
class NetworkInitial extends NetworkState {}
class NetworkLoading extends NetworkState {}


class NetworkLoaded extends NetworkState {
  final List<Device> networks;
  final bool isRefreshing;

  NetworkLoaded({required this.networks, this.isRefreshing = false});

  // to update a few fields while keeping others unchanged
  NetworkLoaded copyWith({
    List<Device>? networks,
    bool? isRefreshing,
  }) {
    return NetworkLoaded(
      networks: networks ?? this.networks,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class NetworkError extends NetworkState {
  final String message;
  NetworkError(this.message);
}