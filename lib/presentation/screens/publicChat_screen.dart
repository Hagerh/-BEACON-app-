import 'package:flutter/material.dart';
import 'package:projectdemo/constants/colors.dart';
import 'package:projectdemo/presentation/widgets/voice_widget.dart';


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

  final TextEditingController _broadcastController = TextEditingController();

  void _showBroadcastDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.secondaryBackground,
          title: const Text('Broadcast to all', style: TextStyle(color: AppColors.textPrimary)),
          content: TextField(
            controller: _broadcastController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Type a message to send to all connected devices',
              hintStyle: TextStyle(color: AppColors.textSecondary),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _broadcastController.clear();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.connectionTeal),
              onPressed: () {
                final msg = _broadcastController.text.trim();
                if (msg.isEmpty) return;
                Navigator.of(context).pop();
                _broadcastMessage(msg);
                _broadcastController.clear();
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
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

  void _showPredefinedMessages(BuildContext context, Map<String, dynamic> device) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send to ${device['name']}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ...(_predefinedMessages.map((msg) => ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.alertRed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.send, color: Colors.white),
              ),
              title: Text(msg, style: const TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Sent "$msg" to ${device['name']}'),
                    backgroundColor: AppColors.connectionTeal,
                  ),
                );
              },
            ))),
          ],
        ),
      ),
    );
  }

  void _openPrivateChat(BuildContext context, Map<String, dynamic> device) {
    setState(() {
      device['unread'] = 0;
    });

    Navigator.pushNamed(
      context,
      '/private_chat',
      arguments: device,
    );
  }

  @override
  void dispose() {
    _broadcastController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondaryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.connectionTeal),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Builder(builder: (context) {
                      final total = _connectedDevices.length;
                      final connected = _connectedDevices.where((d) => (d['status'] ?? '').toString() == 'Active').length;
                      final nonConnected = total - connected;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInfoItem(Icons.devices, '$connected', 'Connected'),
                          const SizedBox(width: 40),
                          _buildInfoItem(Icons.group_off, '$nonConnected', 'Not connected'),
                          const SizedBox(width: 40),
                          _buildInfoItem(Icons.devices_other, '$total', 'Total'),
                        ],
                      );
                    }),
                  ],
                ),
              ],
            ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                return _buildDeviceCard(context, device);
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
            child: const Icon(Icons.folder_shared, color: AppColors.primaryBackground),
          ),
          const SizedBox(height: 12),
          const VoiceWidget(),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label, [Color? valueColor]) {
    return Column(
      children: [
        Icon(icon, color: AppColors.connectionTeal, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceCard(BuildContext context, Map<String, dynamic> device) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.secondaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: device['color'],
                      child: Text(
                        device['avatar'],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if ((device['unread'] ?? 0) > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.alertRed,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primaryBackground, width: 1.5),
                          ),
                          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                          child: Center(
                            child: Text(
                              (device['unread'] as int) > 99 ? '99+' : '${device['unread']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        device['deviceId'],
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.signal_cellular_alt,
                            size: 14,
                            color: _getSignalColor(device['signalStrength']),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${device['signalStrength']}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: _getSignalColor(device['signalStrength']),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            device['distance'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(device['status']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    device['status'],
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showPredefinedMessages(context, device),
                    icon: const Icon(Icons.emergency, size: 18),
                    label: const Text('Quick Send'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.alertRed,
                      side: const BorderSide(color: AppColors.alertRed),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openPrivateChat(context, device),
                    icon: const Icon(Icons.chat_bubble, size: 18),
                    label: const Text('Chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.connectionTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getSignalColor(int strength) {
    if (strength >= 80) return AppColors.safeGreen;
    if (strength >= 60) return AppColors.beaconOrange;
    return AppColors.alertRed;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return AppColors.safeGreen;
      case 'Idle':
        return AppColors.warningYellow;
      default:
        return AppColors.textSecondary;
    }
  }
}
