import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projectdemo/business/cubit/network_cubit.dart';
import 'package:projectdemo/business/cubit/network_state.dart';
import 'package:projectdemo/data/model/device_model.dart';
import 'package:projectdemo/presentation/widgets/voice_widget.dart';

class Joinnetworkscreen extends StatelessWidget {
  const Joinnetworkscreen({super.key});

  // here the ui listens to the NetworkCubit by using BlocBuilder.
  // BlocBuilder rebuilds only this widget when NetworkLoaded state changes
  Widget _buildRefreshButton(BuildContext context) {
    return BlocBuilder<NetworkCubit, NetworkState>(
      // Only rebuild for NetworkLoaded state, as that contains the refreshing status
      buildWhen: (previous, current) => current is NetworkLoaded,
      builder: (context, state) {
        bool isRefreshing = false;
        if (state is NetworkLoaded) {
          isRefreshing = state.isRefreshing;
        }
        return ElevatedButton(
          onPressed: isRefreshing
              ? null
              : () => context.read<NetworkCubit>().refreshNetworks(),
          child: isRefreshing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text("Refresh"),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Connected Network "),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromARGB(255, 235, 200, 200),
                Color.fromARGB(255, 164, 236, 246),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildRefreshButton(context),
          ),
          Expanded(
            child: BlocBuilder<NetworkCubit, NetworkState>(
              builder: (context, state) {
                if (state is NetworkInitial || state is NetworkLoading) {
                  // Show loading indicator
                  return const Center(child: CircularProgressIndicator());
                } else if (state is NetworkLoaded) {
                  // Display the list of networks
                  final networks = state.networks;
                  if (networks.isEmpty) {
                    // Display a message if no networks are found
                    return const Center(child: Text("No networks found."));
                  }
                  // Build the list of network cards
                  return _buildNetworkCard(context, state.networks);
                } else if (state is NetworkError) {
                  // Display an error message
                  return Center(child: Text("Error: ${state.message}"));
                }

                return const Center(child: Text("Unknown state."));
              },
            ),
          ),
        ],
      ),
      floatingActionButton: const VoiceWidget(),
    );
  }
}

Widget _buildNetworkCard(BuildContext context, List<Device> networks) {
  return ListView.builder(
    itemCount: networks.length,
    itemBuilder: (context, index) {
      final device = networks[index];
      return GestureDetector(
        onTap: () {
        
          Navigator.pushNamed(
            context,
            '/public_chat',
            arguments: {
              'networkId': device.id,
              'networkStatus': device.status,
              'lastSeen': device.lastSeen,
              'connectors': device.connectors,
            },
          );
        },
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Icon(
              device.status == "Connected" ? Icons.wifi : Icons.wifi_off,
              color: device.status == "Connected" ? Colors.green : Colors.red,
            ),
            title: Text(device.id),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            
                Row(
                  children: [
                    const Icon(Icons.info, size: 16),
                    const SizedBox(width: 4),
                    Text("Status: ${device.status}"),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16),
                    const SizedBox(width: 4),
                    Text("Last Seen: ${device.lastSeen}"),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16),
                    const SizedBox(width: 4),
                    Text("Connectors: ${device.connectors}"),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
