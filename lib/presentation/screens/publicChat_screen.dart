import 'package:flutter/material.dart';
import 'package:projectdemo/constants/colors.dart';
import 'package:projectdemo/presentation/widgets/voice_widget.dart';
import 'package:projectdemo/presentation/widgets/device_card.dart';
import 'package:projectdemo/presentation/widgets/info_summary.dart';
import 'package:projectdemo/presentation/widgets/quick_message.dart';
import 'package:projectdemo/presentation/widgets/broadcast_dialog.dart';

class PublicChatScreen extends StatefulWidget {
  const PublicChatScreen({super.key});

  @override
  State<PublicChatScreen> createState() => _PublicChatScreenState();
}

class _PublicChatScreenState extends State<PublicChatScreen> {
  List<Map<String, dynamic>> _connectedDevices = [];
  String _networkName = '';
  int _totalConnectors = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get the network data  from joinNetwork screen
    final Map<String, dynamic>? networkData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (networkData != null) {
      _networkName = networkData['networkId'] ?? 'Unknown Network';
      _totalConnectors = networkData['connectors'] ?? 0;

      // Load devices based on the network
      _loadDevicesForNetwork(_networkName, _totalConnectors);
    }
  }

  void _loadDevicesForNetwork(String networkName, int connectorCount) {
    // TODO: Replace with real data

    final allDevices = [
      {
        'name': 'Sarah Mitchell',
        'deviceId': 'Device #A123',
        'status': 'Active',
        'unread': 2,
        'signalStrength': 85,
        'distance': '50m',
        'avatar': 'S',
        'color': AppColors.beaconOrange,
      },
      {
        'name': 'John Parker',
        'deviceId': 'Device #B456',
        'status': 'Active',
        'unread': 0,
        'signalStrength': 92,
        'distance': '30m',
        'avatar': 'J',
        'color': AppColors.connectionTeal,
      },
      {
        'name': 'Emily Chen',
        'deviceId': 'Device #C789',
        'status': 'Idle',
        'unread': 1,
        'signalStrength': 68,
        'distance': '120m',
        'avatar': 'E',
        'color': AppColors.infoBlue,
      },
      {
        'name': 'Michael Brown',
        'deviceId': 'Device #D012',
        'status': 'Active',
        'unread': 0,
        'signalStrength': 78,
        'distance': '80m',
        'avatar': 'M',
        'color': AppColors.beaconOrange,
      },
      {
        'name': 'Lisa Anderson',
        'deviceId': 'Device #E345',
        'status': 'Away',
        'unread': 4,
        'signalStrength': 55,
        'distance': '150m',
        'avatar': 'L',
        'color': AppColors.infoBlue,
      },
    ];

    setState(() {
      _connectedDevices = allDevices.take(connectorCount).toList();
    });
  }

  final List<String> _predefinedMessages = [
    '🆘 Need immediate help!',
    '📍 Share my location',
    '⚠️ Emergency situation',
    '🏥 Medical assistance needed',
    '🔥 Fire emergency',
    '👮 Security alert',
  ];

  void _showBroadcastDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          BroadcastDialog(onSend: (msg) => _broadcastMessage(msg)),
    );
  }

  void _broadcastMessage(String message) {
    final count = _connectedDevices.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Broadcast sent to $count devices'),
        backgroundColor: AppColors.connectionTeal,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showPredefinedMessages(
    BuildContext context,
    Map<String, dynamic> device,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => QuickMessageSheet(
        device: device,
        messages: _predefinedMessages,
        onSend: (msg) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sent "$msg" to ${device['name']}'),
              backgroundColor: AppColors.connectionTeal,
            ),
          );
        },
      ),
    );
  }

  void _openPrivateChat(BuildContext context, Map<String, dynamic> device) {
    setState(() {
      device['unread'] = 0;
    });

    Navigator.pushNamed(context, '/private_chat', arguments: device);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showExitDialog() {
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
        title: const Text('Podcast '),
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
            onPressed: _showBroadcastDialog,
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _showExitDialog();
          },
        ),
      ),
      body: Column(
        children: [
          Builder(
            builder: (context) {
              final total = _connectedDevices.length;
              final connected = _connectedDevices
                  .where((d) => (d['status'] ?? '').toString() == 'Active')
                  .length;

              return InfoSummary(total: total, connected: connected);
            },
          ),

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
                    '${_connectedDevices.length}',
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
              itemCount: _connectedDevices.length,
              itemBuilder: (context, index) {
                final device = _connectedDevices[index];
                return DeviceCard(
                  device: device,
                  onChat: () => _openPrivateChat(context, device),
                  onQuickSend: () => _showPredefinedMessages(context, device),
                  onTap: () => _openPrivateChat(context, device),
                );
              },
            ),
          ),
        ],
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
