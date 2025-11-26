import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projectdemo/business/cubit/networkDashboard_cubit.dart';
import 'package:projectdemo/business/cubit/networkDashboard_state.dart';
import 'package:projectdemo/constants/colors.dart';
import 'package:projectdemo/constants/settings.dart';
import 'package:projectdemo/data/model/deviceDetiles_model.dart';
import 'package:projectdemo/presentation/widgets/voice_widget.dart';
import 'package:projectdemo/presentation/widgets/device_card.dart';
import 'package:projectdemo/presentation/widgets/info_summary.dart';
import 'package:projectdemo/presentation/widgets/quick_message.dart';
import 'package:projectdemo/presentation/widgets/broadcast_dialog.dart';

class PublicChatScreen extends StatelessWidget {
  const PublicChatScreen({super.key});

  void _showBroadcastDialog(BuildContext context) {
    final cubit = context.read<NetworkDashboardCubit>();
    showDialog(
      context: context,
      builder: (_) => BroadcastDialog(
        onSend: (msg) {
          cubit.broadcastMessage(msg); // Call Cubit action
          final count =
              (cubit.state as NetworkDashboardLoaded).connectedDevices.length;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Broadcast sent to $count devices'),
              backgroundColor: AppColors.connectionTeal,
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  void _showPredefinedMessages(BuildContext context, DeviceDetail device) {
    final List<String> predefinedMessages = [
      '🆘 Need immediate help!',
      '📍 Share my location',
      '⚠️ Emergency situation',
      '🏥 Medical assistance needed',
      '🔥 Fire emergency',
      '👮 Security alert',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => QuickMessageSheet(
        device: {
          'name': device.name,
          'deviceId': device.deviceId,
        }, // Convert back to map for the widget
        messages: predefinedMessages,
        onSend: (msg) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sent "$msg" to ${device.name}'),
              backgroundColor: AppColors.connectionTeal,
            ),
          );
        },
      ),
    );
  }

  void _openPrivateChat(BuildContext context, DeviceDetail device) {
    //  Tell the Cubit to mark unread count as 0
    context.read<NetworkDashboardCubit>().markDeviceMessagesAsRead(
      device.deviceId, 
    );

    Navigator.pushNamed(
      context,
      chatScreen,
      arguments: {
        'name': device.name,
        'avatar': device.avatar,
        'color': device.color,
        'status': device.status,
      },
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Exit"),
          content: const Text("Are you sure you want to exit?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text("Exit"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: BlocBuilder<NetworkDashboardCubit, NetworkDashboardState>(
          builder: (context, state) {
            if (state is NetworkDashboardLoaded) {
              return Text(state.networkName);
            } else if (state is NetworkDashboardLoading) {
              return Text(state.networkName);
            }
            return const Text('Network Dashboard');
          },
        ),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign),
            tooltip: 'Broadcast',
            onPressed: () => _showBroadcastDialog(context),
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitDialog(context),
        ),
      ),

      body: BlocBuilder<NetworkDashboardCubit, NetworkDashboardState>(
        builder: (context, state) {
          if (state is NetworkDashboardLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NetworkDashboardError) {
            return Center(child: Text("Error: ${state.message}"));
          }

          if (state is NetworkDashboardLoaded) {
            final devices = state.connectedDevices;
            final total = devices.length;
            final connected = devices.where((d) => d.status == 'Active').length;

            return Column(
              children: [
                InfoSummary(total: total, connected: connected),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text(
                        'Connected Devices',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.connectionTeal,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$total',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return DeviceCard(
                        device: device,
                        onChat: () => _openPrivateChat(context, device),
                        onQuickSend: () =>
                            _showPredefinedMessages(context, device),
                        onTap: () => _openPrivateChat(context, device),
                      );
                    },
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, "/resources");
            },
            backgroundColor: AppColors.buttonPrimary,
            heroTag: 'resourcesBtn',
            child: const Icon(
              Icons.folder_shared,
              color: AppColors.primaryBackground,
            ),
          ),
          const SizedBox(height: 12),
          const VoiceWidget(),
        ],
      ),
    );
  }
}
