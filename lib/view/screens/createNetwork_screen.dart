import 'dart:async';
import 'package:flutter/material.dart';
import 'package:projectdemo/constants/colors.dart';
import 'package:projectdemo/view/widgets/voice_widget.dart';

class ConnectedUser {
  final String id;
  final String name;
  final String joinedAt;
  final int maxConnections = 5;

  ConnectedUser({required this.id, required this.name, required this.joinedAt});
}

class CreateNetworkScreen extends StatefulWidget {
  const CreateNetworkScreen({super.key});

  @override
  State<CreateNetworkScreen> createState() => _CreateNetworkScreenState();
}

class _CreateNetworkScreenState extends State<CreateNetworkScreen> {
  final TextEditingController _networkNameController = TextEditingController();
  final TextEditingController _networkMaxConnectionsController =
      TextEditingController(text: '5');
  bool _isNetworkActive = false; /////////
  bool _isStarting = false;
  List<ConnectedUser> _connectedUsers = [];
  String _networkId = '';

  @override
  void initState() {
    super.initState();
  }

  /////////////////
  @override
  void dispose() {
    _networkNameController.dispose();
    _networkMaxConnectionsController.dispose();
    super.dispose();
  }

  void _startNetwork() async {
    if (_networkNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a network name'),
          backgroundColor: AppColors.alertRed,
        ),
      );
      return;
    }

    setState(() {
      _isStarting = true;
    });

    // Simulate network initialization
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isStarting = false;
      _isNetworkActive = true;
      _networkId = 'BEACON-${DateTime.now().millisecondsSinceEpoch % 10000}';
    });

    // Start listening for connections (mock data for now)
    _listenForConnections();
  }

  // TODO: Implement real peer connection service
  void _listenForConnections() {
    setState(() {
      _connectedUsers.add(
        ConnectedUser(
          id: '${_connectedUsers.length + 1}',
          name: 'Device ${_connectedUsers.length + 1}',
          joinedAt: DateTime.now().toString(),
        ),
      );
      _connectedUsers.add(
        ConnectedUser(
          id: '${_connectedUsers.length + 1}',
          name: 'Device ${_connectedUsers.length + 1}',
          joinedAt: DateTime.now().toString(),
        ),
      );
    });
  }

  void _stopNetwork() {
    setState(() {
      _isNetworkActive = false;
      _connectedUsers.clear();
      _networkId = '';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Network stopped successfully'),
        backgroundColor: AppColors.alertRed,
      ),
    );
  }

  void _disconnectUser(ConnectedUser user) {
    setState(() {
      _connectedUsers.remove(user);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${user.name} has been disconnected'),
        backgroundColor: AppColors.alertRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_isNetworkActive) ...[
                _buildNetworkSetupCard(),
                const SizedBox(height: 16),
                _buildStartButton(),
              ] else ...[
                _buildNetworkInfoCard(),
                const SizedBox(height: 16),
                _buildConnectedUsers(),
                const SizedBox(height: 16),
                _buildStopButton(),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: const VoiceWidget(),
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

  Widget _buildStartButton() {
    return ElevatedButton(
      onPressed: _isStarting ? null : _startNetwork,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.alertRed,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: _isStarting
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

  Widget _buildNetworkInfoCard() {
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
            _buildInfoRow(
              Icons.label,
              'Network Name',
              _networkNameController.text,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.tag, 'Network ID', _networkId),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.people,
              'Connected Users',
              '${_connectedUsers.length} / ${_networkMaxConnectionsController.text}',
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

  Widget _buildConnectedUsers() {
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
        _connectedUsers.isEmpty
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
                itemCount: _connectedUsers.length,
                itemBuilder: (context, index) {
                  final user = _connectedUsers[index];
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
                              Text('Joined: ${user.joinedAt}'),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Network?'),
        content: Text(
          'Are you sure you want to stop the network? All ${_connectedUsers.length} connected users will be disconnected.',
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
