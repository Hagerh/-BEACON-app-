import 'package:flutter/material.dart';

// Reusable empty state widget
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final Color? textColor;
  final double iconSize;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.textColor,
    this.iconSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColor =
        textColor ??
        Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize, color: iconColor ?? defaultColor),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: defaultColor, fontSize: 14)),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(color: defaultColor, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
