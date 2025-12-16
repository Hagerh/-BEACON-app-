import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projectdemo/core/constants/colors.dart';
import 'package:projectdemo/data/models/connected_users_model.dart';
import 'package:projectdemo/business/cubit/create_network_cubit.dart';
import 'package:projectdemo/business/cubit/create_network_state.dart';
import 'package:projectdemo/presentation/widgets/voice_widget.dart';
import 'package:projectdemo/presentation/widgets/settings_card.dart';
import 'package:projectdemo/presentation/widgets/settings_section_header.dart';
import 'package:projectdemo/presentation/widgets/info_row.dart';
import 'package:projectdemo/presentation/widgets/confirmation_dialog.dart';
import 'package:projectdemo/presentation/widgets/input_dialog.dart';
import 'package:projectdemo/presentation/widgets/empty_state.dart';

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
    return SettingsCard(
      backgroundColor: AppColors.resourceNeed,
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
          InfoRow(
            icon: Icons.label,
            label: 'Network Name',
            value: state.networkName,
          ),
          const SizedBox(height: 16),
          InfoRow(
            icon: Icons.people,
            label: 'Connected Users',
            value: '${state.connectedUsers.length} / ${state.maxConnections}',
          ),
          const SizedBox(height: 12),
          const InfoRow(
            icon: Icons.signal_wifi_4_bar,
            label: 'Status',
            value: 'Listening for connections...',
          ),
        ],
      ),
    );
  }

  static Widget _buildMaxConnectionsCard(
    CreateNetworkActive state,
    BuildContext context,
  ) {
    return SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsSectionHeader(
            icon: Icons.settings,
            title: 'Network Settings',
            iconColor: AppColors.connectionTeal,
            textColor: AppColors.textPrimary,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Max Connections: ${state.maxConnections}',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              ElevatedButton.icon(
                onPressed: () => _showEditMaxConnectionsDialog(context, state),
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
            ? SettingsCard(
                child: EmptyState(
                  icon: Icons.devices,
                  title: 'No devices connected yet',
                  subtitle: 'Waiting for users to join...',
                  iconColor: AppColors.textSecondary,
                  textColor: AppColors.textSecondary,
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
    InputDialog.show(
      context: context,
      title: 'Edit Max Connections',
      label: 'Max Connections',
      hintText: 'Enter max connections',
      initialValue: state.maxConnections.toString(),
      keyboardType: TextInputType.number,
      validator: (value) {
        final newMax = int.tryParse(value ?? '');
        if (newMax == null || newMax < 2) {
          return 'Max connections must be at least 2';
        }
        return null;
      },
      onSave: (value) {
        // TODO: Add method to update max connections in Cubit
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Max connections update not yet implemented'),
            backgroundColor: AppColors.infoBlue,
          ),
        );
      },
    );
  }

  static void _showStopAlert(BuildContext context) {
    final state = context.read<CreateNetworkCubit>().state;
    final userCount = state is CreateNetworkActive
        ? state.connectedUsers.length
        : 0;

    ConfirmationDialog.show(
      context: context,
      title: 'Stop Network?',
      content:
          'Are you sure you want to stop the network? All $userCount connected users will be disconnected.',
      confirmText: 'Stop Network',
      confirmColor: AppColors.alertRed,
      icon: Icons.warning,
      onConfirm: () {
        context.read<CreateNetworkCubit>().stopNetwork();
      },
    );
  }

  static void _showDisconnectAlert(BuildContext context, ConnectedUser user) {
    ConfirmationDialog.show(
      context: context,
      title: 'Disconnect User',
      content: 'Are you sure you want to disconnect ${user.name}?',
      confirmText: 'Disconnect',
      confirmColor: AppColors.alertRed,
      icon: Icons.person_remove,
      onConfirm: () {
        context.read<CreateNetworkCubit>().disconnectUser(user.id);
      },
    );
  }
}
