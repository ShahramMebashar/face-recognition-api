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

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radius12),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: record.isAuthorized
                  ? Colors.green.shade600
                  : Colors.red.shade600,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                record.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeFormat.format(record.timestamp),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.grey600,
                  ),
                ),
              ],
            ),
          ),

          // Status badge
          if (record.isAuthorized)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 14,
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Present',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.help_outline,
                    size: 14,
                    color: Colors.red.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Unknown',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
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
