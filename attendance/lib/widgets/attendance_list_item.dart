import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../theme/app_theme.dart';

class AttendanceListItem extends StatelessWidget {
  final AttendanceRecord record;

  const AttendanceListItem({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('MMM d, y');

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radius12),
        border: Border.all(
          color: record.isAuthorized ? AppTheme.grey200 : AppTheme.grey300,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: record.isAuthorized ? AppTheme.grey900 : AppTheme.grey400,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                record.name[0].toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacing16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppTheme.spacing4),
                Row(
                  children: [
                    Text(
                      timeFormat.format(record.timestamp),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      ' · ',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      dateFormat.format(record.timestamp),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing12,
              vertical: AppTheme.spacing4,
            ),
            decoration: BoxDecoration(
              color: record.isAuthorized
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              borderRadius: BorderRadius.circular(AppTheme.radius8),
              border: Border.all(
                color: record.isAuthorized
                    ? Colors.green.shade200
                    : Colors.red.shade200,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  record.isAuthorized ? Icons.check_circle : Icons.cancel,
                  size: 14,
                  color: record.isAuthorized
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  record.isAuthorized ? 'Present' : 'Unknown',
                  style: TextStyle(
                    color: record.isAuthorized
                        ? Colors.green.shade900
                        : Colors.red.shade900,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
