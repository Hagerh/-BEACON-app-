import 'package:flutter/material.dart';
import 'package:projectdemo/constants/colors.dart';

class InfoSummary extends StatelessWidget {
  final int total;
  final int connected;

  const InfoSummary({super.key, required this.total, required this.connected});

  @override
  Widget build(BuildContext context) {
    final nonConnected = total - connected;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.connectionTeal),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(Icons.devices, '$connected', 'Connected'),
          const SizedBox(width: 40),
          _buildInfoItem(Icons.group_off, '$nonConnected', 'Not connected'),
          const SizedBox(width: 40),
          _buildInfoItem(Icons.devices_other, '$total', 'Total'),
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
}

