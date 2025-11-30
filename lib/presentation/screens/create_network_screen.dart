import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projectdemo/core/constants/colors.dart';
import 'package:projectdemo/data/models/connected_users_model.dart';
import 'package:projectdemo/business/cubit/create_network_cubit.dart';
import 'package:projectdemo/business/cubit/create_network_state.dart';
import 'package:projectdemo/presentation/widgets/voice_widget.dart';

class CreateNetworkScreen extends StatefulWidget {
  const CreateNetworkScreen({super.key});

  @override
  State<CreateNetworkScreen> createState() => _CreateNetworkScreenState();
}

class _CreateNetworkScreenState extends State<CreateNetworkScreen> {
  final TextEditingController _networkNameController = TextEditingController();
  final TextEditingController _networkMaxConnectionsController =
      TextEditingController(text: '5');

  @override
  void dispose() {
    _networkNameController.dispose();
    _networkMaxConnectionsController.dispose();
    super.dispose();
  }

  void _startNetwork() {
    final networkName = _networkNameController.text.trim();
    final maxConnections =
        int.tryParse(_networkMaxConnectionsController.text) ?? 5;

    context.read<CreateNetworkCubit>().startNetwork(
      networkName: networkName,
      maxConnections: maxConnections,
    );
  }

  void _stopNetwork() {
    context.read<CreateNetworkCubit>().stopNetwork();
  }

  void _disconnectUser(ConnectedUser user) {
    context.read<CreateNetworkCubit>().disconnectUser(user.id);
  }

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

        // Show success message when network starts
        if (state is CreateNetworkActive && state.connectedUsers.length == 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Network "${state.networkName}" created successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Show message when network stops
        if (state is CreateNetworkInitial) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Network stopped successfully'),
              backgroundColor: AppColors.alertRed,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Create Network"),
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
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (state is CreateNetworkInitial) ...[
                      _buildNetworkSetupCard(),
                      const SizedBox(height: 16),
                      _buildStartButton(false),
                    ] else if (state is CreateNetworkStarting) ...[
                      _buildNetworkSetupCard(),
                      const SizedBox(height: 16),
                      _buildStartButton(true),
                    ] else if (state is CreateNetworkActive) ...[
                      _buildNetworkInfoCard(state),
                      const SizedBox(height: 16),
                      _buildConnectedUsers(state.connectedUsers),
                      const SizedBox(height: 16),
                      _buildStopButton(),
                    ],
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

  Widget _buildNetworkSetupCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.router, color: AppColors.alertRed, size: 40),
                const SizedBox(width: 12),
                Text(
                  'Setup Your Network',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.alertRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const SizedBox(height: 20),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _networkNameController,
                    decoration: InputDecoration(
                      labelText: 'Network Name',
                      hintText: 'Enter a name for your network',
                      prefixIcon: const Icon(Icons.label),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: AppColors.secondaryBackground,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _networkMaxConnectionsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Max Connections',
                      prefixIcon: const Icon(Icons.people),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: AppColors.secondaryBackground,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.infoBlue.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.infoBlue),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          Text(
                            'You will be the host of this network.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            'Other users can join your network.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton(bool isStarting) {
    return ElevatedButton(
      onPressed: isStarting ? null : _startNetwork,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.alertRed,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: isStarting
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Starting Network...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            )
          : Text(
              'Start Network',
              style: TextStyle(fontSize: 16, color: AppColors.borderLight),
            ),
    );
  }

  Widget _buildNetworkInfoCard(CreateNetworkActive state) {
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
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, color: Colors.lightGreen, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
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
            _buildInfoRow(Icons.tag, 'Network ID', state.networkId),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
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

  Widget _buildConnectedUsers(List<ConnectedUser> connectedUsers) {
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
                              Icon(Icons.fingerprint, size: 14),
                              const SizedBox(width: 4),
                              Text('ID: ${user.id}'),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 14),
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
                        onPressed: () => _showDisconnectAlert(user),
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildStopButton() {
    return ElevatedButton(
      onPressed: () => _showStopAlert(),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.alertRed,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        'Stop Network',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showStopAlert() {
    final state = context.read<CreateNetworkCubit>().state;
    final userCount = state is CreateNetworkActive
        ? state.connectedUsers.length
        : 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Network?'),
        content: Text(
          'Are you sure you want to stop the network? All $userCount connected users will be disconnected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _stopNetwork();
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

  void _showDisconnectAlert(ConnectedUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect User'),
        content: Text('Are you sure you want to disconnect ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _disconnectUser(user);
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
