import 'package:flutter/material.dart';
import '../../constants/colors.dart';


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
        body:Column(
          children: [
            Text("data"),
          ],
        )
    );
  }
}
