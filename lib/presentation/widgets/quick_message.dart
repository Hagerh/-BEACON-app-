import 'package:flutter/material.dart';
import 'package:projectdemo/constants/colors.dart';

class QuickMessageSheet extends StatelessWidget {
  final Map<String, dynamic> device;
  final List<String> messages;
  final void Function(String message)? onSend;

  const QuickMessageSheet({
    super.key,
    required this.device,
    required this.messages,
    this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
          ...messages.map((msg) => ListTile(
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
                  if (onSend != null) onSend!(msg);
                },
              )),
        ],
      ),
    );
  }
}
