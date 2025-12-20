import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projectdemo/core/constants/colors.dart';
import 'package:projectdemo/data/models/device_detail_model.dart';
import 'package:projectdemo/business/cubit/network_dashboard/network_dashboard_cubit.dart';
import 'package:projectdemo/business/cubit/network_dashboard/network_dashboard_state.dart';
import 'package:projectdemo/data/local/database_helper.dart';
import 'package:projectdemo/data/models/device_model.dart';
import 'package:projectdemo/presentation/routes/app_routes.dart';
import 'package:projectdemo/presentation/widgets/voice_widget.dart';
import 'package:projectdemo/presentation/widgets/device_card.dart';
import 'package:projectdemo/presentation/widgets/info_summary.dart';
import 'package:projectdemo/presentation/widgets/quick_message.dart';
import 'package:projectdemo/presentation/widgets/broadcast_dialog.dart';
import 'package:projectdemo/presentation/screens/network_settings_screen.dart';
import 'package:projectdemo/presentation/widgets/footer_widget.dart';

class NetworkDashboardScreen extends StatefulWidget {
  final String networkName;

  const NetworkDashboardScreen({super.key, required this.networkName});

  @override
  State<NetworkDashboardScreen> createState() => _NetworkDashboardScreenState();
}

class _NetworkDashboardScreenState extends State<NetworkDashboardScreen> {
  String? _localSummary;
  @override
  void initState() {
    super.initState();
    // Start listening to members stream
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final cubit = context.read<NetworkDashboardCubit>();
        // Only start listening if not already listening (check current state)
        if (cubit.state is NetworkDashboardInitial ||
            cubit.state is NetworkDashboardLoading) {
          cubit.startListening(widget.networkName);
        }
        _loadLocalNetworkSummary();
      } catch (e) {
        debugPrint('Error initializing dashboard: $e');
      }
    });
  }

  Future<void> _loadLocalNetworkSummary() async {
    try {
      final db = DatabaseHelper.instance;
      final network = await db.getNetworkByName(widget.networkName);
      if (network == null) return;
      final nid = network['network_id'] as int?;
      if (nid == null) return;

      final summaries = await db.fetchNetworkSummaries();
      final match = summaries.firstWhere(
        (d) => d.id == nid.toString(),
        orElse: () => Device(id: '', lastSeen: '', status: '', connectors: 0),
      );

      if (match.id.isNotEmpty) {
        // Format last seen time to show date and time
        String formattedDateTime = _formatDateTime(match.lastSeen);
        _localSummary = 'Last Seen $formattedDateTime';
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  String _formatDateTime(String isoString) {
    if (isoString.isEmpty) return '';

    try {
      final dateTime = DateTime.parse(isoString);
      final date = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      final time =
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      return '$date $time';
    } catch (_) {
      return isoString;
    }
  }

  @override
  void dispose() {
    // Don't stop listening here - cubit persists across navigation
    // Listening will only stop when actually leaving the network
    super.dispose();
  }

  void _showBroadcastDialog(BuildContext context) {
    final cubit = context.read<NetworkDashboardCubit>();
    showDialog(
      context: context,
      builder: (_) => BroadcastDialog(
        onSend: (msg) {
          cubit.broadcastMessage(msg);
          final state = cubit.state;
          if (state is NetworkDashboardLoaded) {
            final count = state.connectedDevices.length;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Broadcast sent to $count devices'),
                backgroundColor: AppColors.connectionTeal,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }

  void _showPredefinedMessages(BuildContext context, DeviceDetail device) {
    final cubit = context.read<NetworkDashboardCubit>();
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
        device: {'name': device.name, 'deviceId': device.deviceId},
        messages: predefinedMessages,
        onSend: (msg) {
          cubit.sendPrivateMessage(device.deviceId, msg);
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
    // Mark messages as read
    context.read<NetworkDashboardCubit>().markDeviceMessagesAsRead(
      device.deviceId,
    );

    final dashboardState = context.read<NetworkDashboardCubit>().state;

    Navigator.pushNamed(
      context,
      chatScreen,
      arguments: {
        'name': device.name,
        'avatar': device.avatar,
        'color': device.color,
        'status': device.status,
        'deviceId': device.deviceId,
        'networkId': dashboardState is NetworkDashboardLoaded
            ? dashboardState.networkId
            : null,
      },
    );
  }

  void _showExitDialog(BuildContext context) {
    final cubit = context.read<NetworkDashboardCubit>();
    final state = cubit.state;
    final isServer = state is NetworkDashboardLoaded ? state.isServer : false;

    // Host cannot leave via back button - must use Settings -> Stop Network
    if (isServer) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Cannot Leave Network"),
            content: const Text(
              "As the host, you cannot leave the network as the network will be stopped.\n\n"
              "To stop the network, please use the Settings button and select 'Stop Network'.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("OK"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigate to settings screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: cubit,
                        child: const NetworkSettingsScreen(),
                      ),
                    ),
                  );
                },
                child: const Text("Go to Settings"),
              ),
            ],
          );
        },
      );
      return;
    }

    // Client can leave via back button
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Leave Network"),
          content: const Text("Are you sure you want to leave the network?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog

                await cubit.leaveNetwork();

                // Navigate back to home
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              child: const Text("Leave", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showDeviceOptions(BuildContext context, DeviceDetail device) {
    final cubit = context.read<NetworkDashboardCubit>();
    final state = cubit.state;
    final isServer = state is NetworkDashboardLoaded ? state.isServer : false;

    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Open Chat'),
              onTap: () {
                Navigator.pop(context);
                _openPrivateChat(context, device);
              },
            ),
            ListTile(
              leading: const Icon(Icons.flash_on),
              title: const Text('Quick Send'),
              onTap: () {
                Navigator.pop(context);
                _showPredefinedMessages(context, device);
              },
            ),
            if (isServer)
              ListTile(
                leading: const Icon(Icons.remove_circle, color: Colors.red),
                title: const Text(
                  'Kick User',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  cubit.kickUser(device.deviceId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${device.name} has been removed'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NetworkDashboardCubit, NetworkDashboardState>(
      listener: (context, state) {
        if (state is NetworkDashboardDisconnected) {
          if (state.isServer) {
            // Host goes to Home Screen
            Navigator.pushNamedAndRemoveUntil(
              context,
              landingScreen,
              (route) => false,
            );
          } else {
            // Client goes back to Join Network Screen
            Navigator.pushNamedAndRemoveUntil(
              context,
              networkScreen,
              (route) => route.settings.name == landingScreen,
            );
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: BlocBuilder<NetworkDashboardCubit, NetworkDashboardState>(
            builder: (context, state) {
              if (state is NetworkDashboardLoaded) {
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            state.networkName,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          if (_localSummary != null)
                            Text(
                              _localSummary!,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (state.isServer)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'HOST',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                  ],
                );
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
            BlocBuilder<NetworkDashboardCubit, NetworkDashboardState>(
              builder: (context, state) {
                final isHost = state is NetworkDashboardLoaded
                    ? state.isServer
                    : false;

                return Row(
                  children: [
                    if (isHost)
                      IconButton(
                        icon: const Icon(Icons.settings),
                        tooltip: 'Network Settings',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<NetworkDashboardCubit>(),
                                child: const NetworkSettingsScreen(),
                              ),
                            ),
                          );
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.campaign),
                      tooltip: 'Broadcast',
                      onPressed: () => _showBroadcastDialog(context),
                    ),
                    if (kDebugMode)
                      IconButton(
                        icon: const Icon(Icons.bug_report),
                        tooltip: 'Add Mock Device (Debug)',
                        onPressed: () {
                          context.read<NetworkDashboardCubit>().addMockDevice();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Mock device added'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
          ],
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _showExitDialog(context),
          ),
        ),
        body: BlocBuilder<NetworkDashboardCubit, NetworkDashboardState>(
          builder: (context, state) {
            if (state is NetworkDashboardInitial ||
                state is NetworkDashboardLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is NetworkDashboardError) {
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
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                      child: const Text('Go Home'),
                    ),
                  ],
                ),
              );
            }

            if (state is NetworkDashboardLoaded) {
              final devices = state.connectedDevices;
              final total = devices.length;
              final connected = devices
                  .where((d) => d.status == 'Active')
                  .length;

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
                    child: devices.isEmpty
                        ? const Center(
                            child: Text('Waiting for devices to join...'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: devices.length,
                            itemBuilder: (context, index) {
                              final device = devices[index];
                              return DeviceCard(
                                device: device,
                                onChat: () => _openPrivateChat(context, device),
                                onQuickSend: () =>
                                    _showPredefinedMessages(context, device),
                                onTap: () =>
                                    _showDeviceOptions(context, device),
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
          children: [const SizedBox(height: 12), const VoiceWidget()],
        ),
        bottomNavigationBar: const FooterWidget(currentPage: 0),
      ),
    );
  }
}