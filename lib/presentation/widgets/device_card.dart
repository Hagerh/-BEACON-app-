import 'package:flutter/material.dart';
import 'package:projectdemo/constants/colors.dart';
import 'package:projectdemo/data/model/deviceDetiles_model.dart';

class DeviceCard extends StatelessWidget {
  final DeviceDetail device;
  final VoidCallback onChat;
  final VoidCallback onQuickSend;
  final VoidCallback? onTap;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onChat,
    required this.onQuickSend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.secondaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.borderLight),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Avatar + unread badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 28,
                         backgroundColor: device.color ?? AppColors.infoBlue,
                        child: Text(
                          device.avatar ?? '?',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if ((device.unread ?? 0) > 0)
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
                                (device.unread as int) > 99 ? '99+' : '${device.unread}',
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
                          device.name ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          device.deviceId?? '',
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
                              color: _getSignalColor(device.signalStrength?? 0),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${device.signalStrength ?? 0}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: _getSignalColor(device.signalStrength ?? 0),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              device.distance?? '',
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
                      color: _getStatusColor(device.status ?? ''),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      device.status?? '',
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
                      onPressed: onQuickSend,
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
                      onPressed: onChat,
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
      case 'Away':
        return AppColors.borderLight;
      default:
        return AppColors.textSecondary;
    }
  }
}
