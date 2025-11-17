import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../services/attendance_api_service.dart';
import '../theme/app_theme.dart';

class ActivitiesScreen extends StatefulWidget {
  final AttendanceApiService apiService;

  const ActivitiesScreen({
    super.key,
    required this.apiService,
  });

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen>
    with AutomaticKeepAliveClientMixin {
  List<AttendanceRecord> _records = [];
  StreamSubscription<AttendanceRecord>? _sseSubscription;
  bool _isLoading = true;
  String? _error;
  String _filter = 'all'; // all, authorized, unauthorized

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _connectToSSE();
  }

  @override
  void dispose() {
    _sseSubscription?.cancel();
    super.dispose();
  }

  void _connectToSSE() {
    print('🔄 Activities: Connecting to SSE stream...');
    try {
      final stream = widget.apiService.connectSSE();
      _sseSubscription = stream.listen(
        (record) {
          print(
              '🔄 Activities: Received SSE event - Name: ${record.name}, Status: ${record.status}');
          setState(() {
            _records.insert(0, record);
          });
        },
        onError: (error) {
          print('❌ Activities: SSE error: $error');
          Future.delayed(const Duration(seconds: 5), _connectToSSE);
        },
        onDone: () {
          print('⚠️ Activities: SSE connection closed');
          Future.delayed(const Duration(seconds: 5), _connectToSSE);
        },
      );
    } catch (e) {
      print('❌ Activities: Failed to connect to SSE: $e');
      Future.delayed(const Duration(seconds: 5), _connectToSSE);
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final records = await widget.apiService.getRecentAttendance(limit: 100);
      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<AttendanceRecord> get _filteredRecords {
    if (_filter == 'authorized') {
      return _records.where((r) => r.isAuthorized).toList();
    } else if (_filter == 'unauthorized') {
      return _records.where((r) => !r.isAuthorized).toList();
    }
    return _records;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppTheme.grey50,
      appBar: AppBar(
        title: const Text('Activities'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            color: Colors.white,
            child: Row(
              children: [
                _buildFilterChip('All', 'all', _records.length),
                const SizedBox(width: AppTheme.spacing8),
                _buildFilterChip(
                  'Present',
                  'authorized',
                  _records.where((r) => r.isAuthorized).length,
                ),
                const SizedBox(width: AppTheme.spacing8),
                _buildFilterChip(
                  'Unknown',
                  'unauthorized',
                  _records.where((r) => !r.isAuthorized).length,
                ),
              ],
            ),
          ),

          // Records list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.black))
                : _error != null
                    ? _buildError()
                    : _filteredRecords.isEmpty
                        ? _buildEmptyState()
                        : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _filter == value;
    Color bgColor;
    Color borderColor;
    Color textColor;

    if (value == 'authorized') {
      bgColor = isSelected ? Colors.green.shade700 : Colors.green.shade50;
      borderColor = Colors.green.shade700;
      textColor = isSelected ? Colors.white : Colors.green.shade900;
    } else if (value == 'unauthorized') {
      bgColor = isSelected ? Colors.red.shade700 : Colors.red.shade50;
      borderColor = Colors.red.shade700;
      textColor = isSelected ? Colors.white : Colors.red.shade900;
    } else {
      bgColor = isSelected ? AppTheme.black : AppTheme.grey100;
      borderColor = AppTheme.black;
      textColor = isSelected ? Colors.white : AppTheme.black;
    }

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _filter = value;
          });
        },
        borderRadius: BorderRadius.circular(AppTheme.radius12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppTheme.spacing12,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppTheme.radius12),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    // Group records by date
    final grouped = <String, List<AttendanceRecord>>{};
    for (var record in _filteredRecords) {
      final dateKey = DateFormat('yyyy-MM-dd').format(record.timestamp);
      grouped.putIfAbsent(dateKey, () => []).add(record);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final dateKey = grouped.keys.elementAt(index);
        final dayRecords = grouped[dateKey]!;
        final date = DateTime.parse(dateKey);
        final isToday =
            DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateKey;
        final dateLabel =
            isToday ? 'Today' : DateFormat('EEEE, MMM d, y').format(date);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppTheme.spacing12,
                horizontal: AppTheme.spacing4,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing12,
                      vertical: AppTheme.spacing4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.black,
                      borderRadius: BorderRadius.circular(AppTheme.radius8),
                    ),
                    child: Text(
                      dateLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Text(
                    '${dayRecords.length} events',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.grey600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            ...dayRecords.map((record) => _ActivityItem(record: record)),
            const SizedBox(height: AppTheme.spacing8),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    String message;
    if (_filter == 'authorized') {
      message = 'No authorized attendances yet';
    } else if (_filter == 'unauthorized') {
      message = 'No unknown visits recorded';
    } else {
      message = 'No activities yet';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: AppTheme.grey300,
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.grey600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.grey400),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'Failed to load activities',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing24),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final AttendanceRecord record;

  const _ActivityItem({required this.record});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm:ss');

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radius12),
        border: Border.all(
          color:
              record.isAuthorized ? Colors.green.shade200 : Colors.red.shade200,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: record.isAuthorized
                  ? Colors.green.shade700
                  : Colors.red.shade700,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                record.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  timeFormat.format(record.timestamp),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.grey600,
                  ),
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
