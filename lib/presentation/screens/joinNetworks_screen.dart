import 'dart:async';

import 'package:flutter/material.dart';
import 'package:projectdemo/presentation/widgets/voice_widget.dart';

class Device {
  final String id;
  final String status;
  final String lastSean;
 
  final int connectors;

  Device({
    required this.lastSean,

    required this.id,
    required this.status,
    required this.connectors,
  });
}

class Joinnetworkscreen extends StatefulWidget {
  const Joinnetworkscreen({super.key});

  @override
  State<Joinnetworkscreen> createState() => _JoinnetworkscreenState();
}

class _JoinnetworkscreenState extends State<Joinnetworkscreen> {
  List<Device> _networks = [];
  Timer? _timer;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadNetwoarks();
  }

  //TODO, implement real data fetching logic
  void _loadNetwoarks() {
    setState(() {
      _networks = [
        Device(
          id: "Emergency hub",
          status: "Connected",
          lastSean: "2 mins ago",
       
          connectors: 3,
        ),
        Device(
          id: "wi-fi-5Ghz",
          status: "Disconnected",
          lastSean: "10 mins ago",
         
          connectors: 2,
        ),
        Device(
          id: "house-wifi",
          status: "Connected",
          lastSean: "1 min ago",
       
          connectors: 5,
        ),
      ];
    });
  }

  void _refreshData() {
    setState(() {
      _isRefreshing = true;
    });

    _timer = Timer(const Duration(seconds: 2), () {
      setState(() {
        _isRefreshing = false;
        _loadNetwoarks();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Connected Network "),
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
          Padding(padding: const EdgeInsets.all(16.0), child: _refreshButton()),
          Expanded(child: _buildNetworkCard()),
        ],
      ),
      floatingActionButton: const VoiceWidget(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _refreshButton() {
    return ElevatedButton(
      onPressed: _isRefreshing ? null : _refreshData,
      child: _isRefreshing
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text("Refresh"),
    );
  }

  Widget _buildNetworkCard() {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/chat_screen');
      },
      child: ListView.builder(
        itemCount: _networks.length,
        itemBuilder: (context, index) {
          final device = _networks[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(
                device.status == "Connected" ? Icons.wifi : Icons.wifi_off,
                color: device.status == "Connected" ? Colors.green : Colors.red,
              ),
              title: Text(device.id),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, size: 16),
                      SizedBox(width: 4),
                      Text("Status: ${device.status}"),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16),
                      SizedBox(width: 4),
                      Text("Last Seen: ${device.lastSean}"),
                    ],
                  ),
                  
                  Row(
                    children: [
                      Icon(Icons.person, size: 16),
                      SizedBox(width: 4),
                      Text("Connectors: ${device.connectors}"),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
