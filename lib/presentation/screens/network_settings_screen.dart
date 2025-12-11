import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projectdemo/core/constants/colors.dart';
import 'package:projectdemo/data/models/connected_users_model.dart';
import 'package:projectdemo/business/cubit/create_network_cubit.dart';
import 'package:projectdemo/business/cubit/create_network_state.dart';
import 'package:projectdemo/presentation/widgets/voice_widget.dart';

class NetworkSettingsScreen extends StatelessWidget {
  const NetworkSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreateNetworkCubit, CreateNetworkState>(
      listener: (context, state) {
        // Handle error states
        if (state is CreateNetworkError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.alertRed,
            ),
          );
          // Clear error after showing snackbar
          context.read<CreateNetworkCubit>().clearError();
        }

        // Navigate back when network is stopped
        if (state is CreateNetworkInitial) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Network stopped successfully'),
              backgroundColor: AppColors.alertRed,
            ),
          );

          Future.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted) {
              Navigator.pop(context);
            }
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Network Settings"),
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
        body: BlocBuilder<CreateNetworkCubit, CreateNetworkState>(
          builder: (context, state) {
            if (state is! CreateNetworkActive) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.wifi_off,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No active network',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildNetworkInfoCard(state, context),
                    const SizedBox(height: 16),
                    _buildMaxConnectionsCard(state, context),
                    const SizedBox(height: 16),
                    _buildConnectedUsers(state.connectedUsers, context),
                    const SizedBox(height: 16),
                    _buildStopButton(context),
                  ],
                ),
              ),
            );
          },
        ),
        floatingActionButton: const VoiceWidget(),
      ),
    );
  }

  static Widget _buildNetworkInfoCard(
    CreateNetworkActive state,
    BuildContext context,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.resourceNeed,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.lightGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Network Active',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.label, 'Network Name', state.networkName),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.tag, 'Network ID', state.networkName), // .networkId to .networkName
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.people,
              'Connected Users',
              '${state.connectedUsers.length} / ${state.maxConnections}',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.signal_wifi_4_bar,
              'Status',
              'Listening for connections...',
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildMaxConnectionsCard(
    CreateNetworkActive state,
    BuildContext context,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: AppColors.connectionTeal, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Network Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Max Connections: ${state.maxConnections}',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () =>
                      _showEditMaxConnectionsDialog(context, state),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.connectionTeal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 25, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 18,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildConnectedUsers(
    List<ConnectedUser> connectedUsers,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connected Devices:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        connectedUsers.isEmpty
            ? Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.devices,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No devices connected yet',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Waiting for users to join...',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: connectedUsers.length,
                itemBuilder: (context, index) {
                  final user = connectedUsers[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.connectionTeal,
                        child: Icon(Icons.person, color: AppColors.textPrimary),
                      ),
                      title: Text(
                        user.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.fingerprint, size: 14),
                              const SizedBox(width: 4),
                              Text('ID: ${user.id}'),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 14),
                              const SizedBox(width: 4),
                              Text('Joined: ${user.formattedJoinTime}'),
                            ],
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.remove_circle_outline,
                          color: AppColors.alertRed,
                        ),
                        onPressed: () => _showDisconnectAlert(context, user),
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  static Widget _buildStopButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _showStopAlert(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.alertRed,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text(
        'Stop Network',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  static void _showEditMaxConnectionsDialog(
    BuildContext context,
    CreateNetworkActive state,
  ) {
    final controller = TextEditingController(
      text: state.maxConnections.toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Max Connections'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Max Connections',
            hintText: 'Enter max connections',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newMax = int.tryParse(controller.text);
              if (newMax != null && newMax >= 2) {
                // TODO: Add method to update max connections in Cubit
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Max connections update not yet implemented'),
                    backgroundColor: AppColors.infoBlue,
                  ),
                );
                Navigator.pop(dialogContext);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Max connections must be at least 2'),
                    backgroundColor: AppColors.alertRed,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.connectionTeal,
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  static void _showStopAlert(BuildContext context) {
    final state = context.read<CreateNetworkCubit>().state;
    final userCount = state is CreateNetworkActive
        ? state.connectedUsers.length
        : 0;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Stop Network?'),
        content: Text(
          'Are you sure you want to stop the network? All $userCount connected users will be disconnected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<CreateNetworkCubit>().stopNetwork();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertRed,
            ),
            child: const Text(
              'Stop Network',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  static void _showDisconnectAlert(BuildContext context, ConnectedUser user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Disconnect User'),
        content: Text('Are you sure you want to disconnect ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<CreateNetworkCubit>().disconnectUser(user.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertRed,
            ),
            child: const Text(
              'Disconnect',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
