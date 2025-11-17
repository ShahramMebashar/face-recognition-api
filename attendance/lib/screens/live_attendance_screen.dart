import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../services/attendance_api_service.dart';
import '../theme/app_theme.dart';

class LiveAttendanceScreen extends StatefulWidget {
  final AttendanceApiService apiService;

  const LiveAttendanceScreen({
    super.key,
    required this.apiService,
  });

  @override
  State<LiveAttendanceScreen> createState() => _LiveAttendanceScreenState();
}

class _LiveAttendanceScreenState extends State<LiveAttendanceScreen> {
  final List<AttendanceRecord> _liveRecords = [];
  StreamSubscription<AttendanceRecord>? _sseSubscription;
  bool _isConnected = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _connectToSSE();
  }

  @override
  void dispose() {
    _sseSubscription?.cancel();
    super.dispose();
  }

  void _connectToSSE() {
    print('📺 Live: Connecting to SSE stream...');
    setState(() {
      _isConnected = true;
      _error = null;
    });

    try {
      final stream = widget.apiService.connectSSE();
      _sseSubscription = stream.listen(
        (record) {
          print(
              '📺 Live: Received SSE event - Name: ${record.name}, Status: ${record.status}');
          setState(() {
            _liveRecords.insert(0, record);
            // Keep only last 50 records
            if (_liveRecords.length > 50) {
              _liveRecords.removeLast();
            }
          });
          print('📺 Live: Updated records list (${_liveRecords.length} items)');
        },
        onError: (error) {
          print('❌ Live: SSE error: $error');
          setState(() {
            _error = error.toString();
            _isConnected = false;
          });
        },
        onDone: () {
          print('⚠️ Live: SSE connection closed');
          setState(() {
            _isConnected = false;
          });
        },
      );
      print('✅ Live: SSE subscription created');
    } catch (e) {
      print('❌ Live: Failed to connect to SSE: $e');
      setState(() {
        _error = e.toString();
        _isConnected = false;
      });
    }
  }

  void _reconnect() {
    _sseSubscription?.cancel();
    _connectToSSE();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.grey50,
      appBar: AppBar(
        title: const Text('Live Feed'),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppTheme.spacing16),
            child: Center(
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _isConnected ? Colors.green : AppTheme.grey400,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Text(
                    _isConnected ? 'Connected' : 'Disconnected',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: !_isConnected
          ? FloatingActionButton(
              onPressed: _reconnect,
              backgroundColor: AppTheme.black,
              child: const Icon(Icons.refresh, color: AppTheme.white),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_error != null && _liveRecords.isEmpty) {
      return _buildError();
    }

    if (_liveRecords.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
      itemCount: _liveRecords.length,
      itemBuilder: (context, index) {
        return _LiveAttendanceItem(
          record: _liveRecords[index],
          isNew: index == 0,
        );
      },
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.signal_wifi_off,
                size: 48, color: AppTheme.grey400),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'Connection Failed',
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
              onPressed: _reconnect,
              child: const Text('Retry Connection'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing24),
              decoration: BoxDecoration(
                color:
                    _isConnected ? Colors.green.shade50 : Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isConnected
                    ? Icons.visibility_outlined
                    : Icons.signal_wifi_off,
                size: 64,
                color: _isConnected
                    ? Colors.green.shade700
                    : Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: AppTheme.spacing32),
            Text(
              _isConnected ? 'Live Feed Active' : 'Connection Lost',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              _isConnected
                  ? 'Waiting for attendance events...\nNew records will appear here automatically'
                  : 'Tap the refresh button to reconnect',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.grey600,
                  ),
              textAlign: TextAlign.center,
            ),
            if (_isConnected) ...[
              const SizedBox(height: AppTheme.spacing32),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing16,
                  vertical: AppTheme.spacing8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(AppTheme.radius16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    Text(
                      'Listening for events',
                      style: TextStyle(
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LiveAttendanceItem extends StatefulWidget {
  final AttendanceRecord record;
  final bool isNew;

  const _LiveAttendanceItem({
    required this.record,
    required this.isNew,
  });

  @override
  State<_LiveAttendanceItem> createState() => _LiveAttendanceItemState();
}

class _LiveAttendanceItemState extends State<_LiveAttendanceItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    if (widget.isNew) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm:ss');

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing16,
            vertical: AppTheme.spacing4,
          ),
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
                  color: widget.record.isAuthorized
                      ? Colors.green.shade600
                      : Colors.red.shade600,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.record.name[0].toUpperCase(),
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
                      widget.record.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeFormat.format(widget.record.timestamp),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.grey600,
                      ),
                    ),
                  ],
                ),
              ),

              // Status badge
              if (widget.record.isAuthorized)
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
                        color: Colors.green.shade600,
                        size: 14,
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
                        color: Colors.red.shade600,
                        size: 14,
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
        ),
      ),
    );
  }
}
