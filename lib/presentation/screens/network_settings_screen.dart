import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projectdemo/core/constants/colors.dart';
import 'package:projectdemo/business/cubit/network_dashboard_cubit.dart';
import 'package:projectdemo/business/cubit/network_dashboard_state.dart';

class NetworkSettingsScreen extends StatelessWidget {
  const NetworkSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Settings'),
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
      body: BlocBuilder<NetworkDashboardCubit, NetworkDashboardState>(
        builder: (context, state) {
          if (state is NetworkDashboardLoading ||
              state is NetworkDashboardInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NetworkDashboardError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          }

          if (state is! NetworkDashboardLoaded) {
            return const SizedBox.shrink();
          }

          if (!state.isServer) {
            return Center(
              child: Text(
                'Network settings are only available to the host.',
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            );
          }

          final devices = state.connectedDevices;
          final maxConnections = state.maxConnections;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.networkName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Connected devices: ${devices.length}',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        maxConnections != null
                            ? 'Max connections: $maxConnections'
                            : 'Max connections: not limited',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _editNetworkName(context, state.networkName),
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit name'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _editMaxConnections(
                                context,
                                maxConnections,
                                devices.length,
                              ),
                              icon: const Icon(Icons.people),
                              label: const Text('Max connections'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Manage Devices',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              if (devices.isEmpty)
                Text(
                  'No connected devices.',
                  style: TextStyle(color: AppColors.textSecondary),
                )
              else
                ...devices.map((d) {
                  return Card(
                    child: ListTile(
                      title: Text(d.name),
                      subtitle: Text('ID: ${d.deviceId}'),
                      trailing: IconButton(
                        tooltip: 'Kick',
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          context.read<NetworkDashboardCubit>().kickUser(
                            d.deviceId,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${d.name} has been removed'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _confirmStopNetwork(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.alertRed,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Stop Network',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmStopNetwork(BuildContext context) async {
    final cubit = context.read<NetworkDashboardCubit>();

    final shouldStop = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Stop Network'),
          content: const Text(
            'Stopping the network will disconnect all users. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Stop', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldStop == true) {
      await cubit.stopNetwork();
      if (context.mounted) {
        Navigator.of(context).pop(); // back to dashboard
      }
    }
  }

  Future<void> _editNetworkName(
    BuildContext context,
    String currentName,
  ) async {
    final cubit = context.read<NetworkDashboardCubit>();
    final controller = TextEditingController(text: currentName);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Network Name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Network Name',
              hintText: 'Enter a new name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty || value.length < 3) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Network name must be at least 3 characters.',
                      ),
                    ),
                  );
                  return;
                }
                cubit.updateNetworkName(value);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editMaxConnections(
    BuildContext context,
    int? currentMax,
    int currentConnections,
  ) async {
    final cubit = context.read<NetworkDashboardCubit>();
    final controller = TextEditingController(
      text: currentMax?.toString() ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Max Connections'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Max connections',
              hintText: 'e.g. 8',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final raw = controller.text.trim();
                final parsed = int.tryParse(raw);
                if (parsed == null || parsed <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter a valid number greater than 0.',
                      ),
                    ),
                  );
                  return;
                }
                if (parsed < currentConnections) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Cannot be less than current connections ($currentConnections).',
                      ),
                    ),
                  );
                  return;
                }
                cubit.updateMaxConnections(parsed);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
