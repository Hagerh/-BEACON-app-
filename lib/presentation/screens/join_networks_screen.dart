import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import 'package:projectdemo/data/models/user_profile_model.dart';
import 'package:projectdemo/business/cubit/network_discovery_cubit.dart';
import 'package:projectdemo/business/cubit/network_discovery_state.dart';
import 'package:projectdemo/presentation/routes/app_routes.dart';
import 'package:projectdemo/presentation/widgets/voice_widget.dart';

class Joinnetworkscreen extends StatefulWidget {
  final UserProfile currentUser;

  const Joinnetworkscreen({super.key, required this.currentUser});

  @override
  State<Joinnetworkscreen> createState() => _JoinnetworkscreenState();
}

class _JoinnetworkscreenState extends State<Joinnetworkscreen> {
  @override
  void initState() {
    super.initState();
    // Start discovering networks when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NetworkCubit>().startDiscovery(widget.currentUser);
    });
  }

  @override
  void dispose() {
    // Stop discovery when leaving screen
    context.read<NetworkCubit>().stopDiscovery();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Join Network"),
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
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.blue.withOpacity(0.1),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Scanning for nearby networks...",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocConsumer<NetworkCubit, NetworkState>(
              listener: (context, state) {
                if (state is NetworkConnected) {
                  // Navigate to public chat after successful connection
                  if (!context.mounted) return;
                  
                  Navigator.pushReplacementNamed(
                    context,
                    publicChatScreen,
                    arguments: {'device': state.device},
                  );
                } else if (state is NetworkError) {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is NetworkInitial || state is NetworkLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Initializing P2P discovery..."),
                      ],
                    ),
                  );
                } else if (state is NetworkLoaded) {
                  final networks = state.networks;
                  if (networks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.wifi_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "No networks found nearby",
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Make sure a host has created a network",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }
                  return _buildNetworkList(context, networks);
                } else if (state is NetworkConnecting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          "Connecting to ${state.device.deviceName}...",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  );
                } else if (state is NetworkError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Error: ${state.message}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => context
                              .read<NetworkCubit>()
                              .startDiscovery(widget.currentUser),
                          child: const Text("Try Again"),
                        ),
                      ],
                    ),
                  );
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

  Widget _buildNetworkList(
    BuildContext context,
    List<BleDiscoveredDevice> networks,
  ) {
    return ListView.builder(
      itemCount: networks.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final device = networks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.wifi, color: Colors.blue, size: 28),
            ),
            title: Text(
              device.deviceName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.devices, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      device.deviceAddress,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.signal_cellular_alt,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      "Available",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () {
                context.read<NetworkCubit>().connectToNetwork(device);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text("Join"),
            ),
          ),
        );
      },
    );
  }
}
