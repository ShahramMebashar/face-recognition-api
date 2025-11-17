import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radius16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            icon,
            size: 24,
            color: iconColor ?? AppTheme.black,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.black,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.grey600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
