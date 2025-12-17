import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projectdemo/core/constants/colors.dart';
import 'package:projectdemo/business/cubit/create_network_cubit.dart';
import 'package:projectdemo/business/cubit/create_network_state.dart';
import 'package:projectdemo/presentation/routes/app_routes.dart';
import 'package:projectdemo/presentation/widgets/voice_widget.dart';

class CreateNetworkScreen extends StatelessWidget {
  const CreateNetworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    
    return BlocListener<CreateNetworkCubit, CreateNetworkState>(
      listener: (context, state) {
        // Handle error states
        if (state is CreateNetworkError) {
          if (!context.mounted) return; // Prevent showing snackbar if widget is disposed
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.alertRed,
              ),
            );
          } catch (e) {
            debugPrint('Error showing error snackbar: $e');
          }
          // Clear error after showing snackbar
          context.read<CreateNetworkCubit>().clearError();
        }

        // Navigate to public chat when network is created successfully
        // Navigate to public chat when network is created successfully
        if (state is CreateNetworkReady) {
          if (!context.mounted) return;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Network "${state.networkName}" created successfully!',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Navigate to public chat screen with the network name
          Navigator.pushReplacementNamed(
            context,
            publicChatScreen,
            arguments: {'networkName': state.networkName},
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
            final isStarting = state is CreateNetworkStarting;

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _NetworkSetupForm(
                  isStarting: isStarting,
                  onStart: (networkName, maxConnections) {
                    context.read<CreateNetworkCubit>().startNetwork(
                      networkName: networkName,
                      maxConnections: maxConnections,
                    );
                  },
                ),
              ),
            );
          },
        ),
        floatingActionButton: const VoiceWidget(),
      ),
    );
  }
}

// Stateful widget to manage text controllers for network setup
class _NetworkSetupForm extends StatefulWidget {
  final bool isStarting;
  final Function(String networkName, int maxConnections) onStart;

  const _NetworkSetupForm({required this.isStarting, required this.onStart});

  @override
  State<_NetworkSetupForm> createState() => _NetworkSetupFormState();
}

class _NetworkSetupFormState extends State<_NetworkSetupForm> {
  final TextEditingController _networkNameController = TextEditingController();
  final TextEditingController _networkMaxConnectionsController =
      TextEditingController(text: '5');

  @override
  void dispose() {
    _networkNameController.dispose();
    _networkMaxConnectionsController.dispose();
    super.dispose();
  }

  void _handleStart() {
    final networkName = _networkNameController.text.trim();
    final maxConnections =
        int.tryParse(_networkMaxConnectionsController.text) ?? 5;
    widget.onStart(networkName, maxConnections);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: widget.isStarting ? null : _handleStart,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.alertRed,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: widget.isStarting
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
        ),
      ],
    );
  }
}
