import 'package:flutter/material.dart';
import 'package:projectdemo/core/constants/colors.dart';

/// Reusable input dialog for text/number input
class InputDialog extends StatefulWidget {
  final String title;
  final String label;
  final String? hintText;
  final String? initialValue;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Function(String) onSave;
  final String saveButtonText;
  final Color? saveButtonColor;

  const InputDialog({
    super.key,
    required this.title,
    required this.label,
    required this.onSave,
    this.hintText,
    this.initialValue,
    this.keyboardType,
    this.validator,
    this.saveButtonText = 'Save',
    this.saveButtonColor,
  });

  @override
  State<InputDialog> createState() => _InputDialogState();

  /// Helper method to show the dialog
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String label,
    required Function(String) onSave,
    String? hintText,
    String? initialValue,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String saveButtonText = 'Save',
    Color? saveButtonColor,
  }) {
    return showDialog(
      context: context,
      builder: (context) => InputDialog(
        title: title,
        label: label,
        onSave: onSave,
        hintText: hintText,
        initialValue: initialValue,
        keyboardType: keyboardType,
        validator: validator,
        saveButtonText: saveButtonText,
        saveButtonColor: saveButtonColor,
      ),
    );
  }
}

class _InputDialogState extends State<InputDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSave() {
    final value = _controller.text;

    // Validate if validator provided
    if (widget.validator != null) {
      final error = widget.validator!(value);
      if (error != null) {
        setState(() => _errorText = error);
        return;
      }
    }

    Navigator.pop(context);
    widget.onSave(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        keyboardType: widget.keyboardType,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hintText,
          errorText: _errorText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onChanged: (_) {
          if (_errorText != null) {
            setState(() => _errorText = null);
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.saveButtonColor ?? AppColors.connectionTeal,
          ),
          child: Text(
            widget.saveButtonText,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
