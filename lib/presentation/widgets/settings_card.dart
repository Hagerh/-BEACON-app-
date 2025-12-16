import 'package:flutter/material.dart';

// Reusable card wrapper for settings screen widgets
class SettingsCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final double? elevation;

  const SettingsCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.padding,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ?? 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: backgroundColor,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}
