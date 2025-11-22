import 'package:flutter/material.dart';
import 'package:projectdemo/constants/colors.dart';

class BroadcastDialog extends StatefulWidget {
  final void Function(String message)? onSend;

  const BroadcastDialog({super.key, this.onSend});

  @override
  State<BroadcastDialog> createState() => _BroadcastDialogState();
}

class _BroadcastDialogState extends State<BroadcastDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.secondaryBackground,
      title: const Text('Broadcast to all', style: TextStyle(color: AppColors.textPrimary)),
      content: TextField(
        controller: _controller,
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
            _controller.clear();
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.connectionTeal),
          onPressed: () {
            final msg = _controller.text.trim();
            if (msg.isEmpty) return;
            Navigator.of(context).pop();
            if (widget.onSend != null) widget.onSend!(msg);
            _controller.clear();
          },
          child: const Text('Send'),
        ),
      ],
    );
  }
}
