import 'dart:async';
import 'package:flutter/material.dart';
import '../models/attendance_record.dart';
import '../models/attendance_stats.dart';
import '../services/attendance_api_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/attendance_list_item.dart';
import '../theme/app_theme.dart';
import 'faces_screen.dart';
import 'add_face_screen.dart';
import 'live_attendance_screen.dart';
import 'recognize_screen.dart';

class HomeScreen extends StatefulWidget {
  final AttendanceApiService apiService;

  const HomeScreen({
    super.key,
    required this.apiService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AttendanceStats? _stats;
  List<AttendanceRecord> _recentRecords = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription<AttendanceRecord>? _sseSubscription;

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
    print('🏠 Home: Connecting to SSE stream...');
    try {
      final stream = widget.apiService.connectSSE();
      _sseSubscription = stream.listen(
        (record) {
          print(
              '🏠 Home: Received SSE event - Name: ${record.name}, Status: ${record.status}');
          // Add new record to the top of the list
          setState(() {
            _recentRecords.insert(0, record);
            if (_recentRecords.length > 10) {
              _recentRecords.removeLast();
            }
          });
          print(
              '🏠 Home: Updated recent records list (${_recentRecords.length} items)');
          // Refresh stats when new record arrives
          _refreshStats();
        },
        onError: (error) {
          print('❌ Home: SSE error: $error');
          // Silently reconnect on error
          Future.delayed(const Duration(seconds: 5), () {
            print('🔄 Home: Reconnecting after error...');
            _connectToSSE();
          });
        },
        onDone: () {
          print('⚠️ Home: SSE connection closed');
          // Reconnect if connection closes
          Future.delayed(const Duration(seconds: 5), () {
            print('🔄 Home: Reconnecting after done...');
            _connectToSSE();
          });
        },
      );
      print('✅ Home: SSE subscription created');
    } catch (e) {
      print('❌ Home: Failed to connect to SSE: $e');
      // Retry connection after delay
      Future.delayed(const Duration(seconds: 5), () {
        print('🔄 Home: Retrying connection...');
        _connectToSSE();
      });
    }
  }

  Future<void> _refreshStats() async {
    try {
      final stats = await widget.apiService.getStats();
      setState(() {
        _stats = stats;
      });
    } catch (e) {
      // Ignore stats refresh errors
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await widget.apiService.getStats();
      final records = await widget.apiService.getRecentAttendance(limit: 10);

      setState(() {
        _stats = stats;
        _recentRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.black))
          : _error != null
              ? _buildError()
              : _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddFace(),
        backgroundColor: AppTheme.black,
        child: const Icon(Icons.add, color: AppTheme.white),
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
              'Failed to load data',
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

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.black,
      child: ListView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        children: [
          _buildQuickActions(),
          const SizedBox(height: AppTheme.spacing24),
          _buildStats(),
          const SizedBox(height: AppTheme.spacing24),
          _buildRecentAttendance(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                label: 'View Faces',
                icon: Icons.people_outline,
                onTap: () => _navigateToFaces(),
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: _QuickActionButton(
                label: 'Live View',
                icon: Icons.visibility_outlined,
                onTap: () => _navigateToLive(),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing12),
        SizedBox(
          width: double.infinity,
          child: _QuickActionButton(
            label: 'Recognize Face',
            icon: Icons.face_retouching_natural,
            onTap: () => _navigateToRecognize(),
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    if (_stats == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppTheme.spacing16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: AppTheme.spacing12,
          crossAxisSpacing: AppTheme.spacing12,
          childAspectRatio: 1.5,
          children: [
            StatCard(
              label: 'Total Records',
              value: '${_stats!.total}',
              icon: Icons.receipt_long_outlined,
            ),
            StatCard(
              label: 'Authorized',
              value: '${_stats!.authorized}',
              icon: Icons.check_circle_outline,
            ),
            StatCard(
              label: 'Unauthorized',
              value: '${_stats!.unauthorized}',
              icon: Icons.cancel_outlined,
            ),
            StatCard(
              label: 'Unique People',
              value: '${_stats!.uniquePeople}',
              icon: Icons.person_outline,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentAttendance() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to full attendance history
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing16),
        _recentRecords.isEmpty
            ? _buildEmptyState()
            : Column(
                children: _recentRecords
                    .map((record) => AttendanceListItem(record: record))
                    .toList(),
              ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: AppTheme.grey300),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'No attendance records yet',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToFaces() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FacesScreen(apiService: widget.apiService),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToAddFace() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFaceScreen(apiService: widget.apiService),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToLive() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LiveAttendanceScreen(apiService: widget.apiService),
      ),
    );
  }

  void _navigateToRecognize() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecognizeScreen(
          apiBaseUrl: widget.apiService.baseUrl,
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radius12),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing20),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radius12),
          border: Border.all(color: AppTheme.grey200),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppTheme.black),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
