import 'package:flutter/material.dart';



class NetworkDashboardScreen extends StatefulWidget {
  const NetworkDashboardScreen({super.key});

  @override
  State<NetworkDashboardScreen> createState() => _NetworkDashboardScreenState();
}

class _NetworkDashboardScreenState extends State<NetworkDashboardScreen> {
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
              colors: [Color.fromARGB(255, 235, 200, 200), Color.fromARGB(255, 164, 236, 246)],
            ),
          ),
        ),
      ),
        body:ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            ListTile(
              title: Text('Beacon Node Alpha'),
              subtitle: Text('Status: Connected'),
              
            ),
            SizedBox(height: 16),
            ListTile(
            
              title: Text('CDVC-103'),
              subtitle: Text('5 devices connected'),
            ),
            SizedBox(height: 16),
            ListTile(
              
              title: Text('DVC-103'),
              subtitle: Text('Used: 1.2 GB / 5 GB'),
            ),
          ],
        ),
    );
  }
}
