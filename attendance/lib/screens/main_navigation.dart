import 'package:flutter/material.dart';
import '../services/attendance_api_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'activities_screen.dart';
import 'faces_screen.dart';
import 'live_attendance_screen.dart';

class MainNavigation extends StatefulWidget {
  final AttendanceApiService apiService;

  const MainNavigation({
    super.key,
    required this.apiService,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(apiService: widget.apiService),
      ActivitiesScreen(apiService: widget.apiService),
      FacesScreen(apiService: widget.apiService),
      LiveAttendanceScreen(apiService: widget.apiService),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              left: AppTheme.spacing8,
              right: AppTheme.spacing8,
              top: AppTheme.spacing8,
              bottom: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.history_rounded,
                  label: 'Activities',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.people_rounded,
                  label: 'People',
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.sensors_rounded,
                  label: 'Live',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 26,
                color: isSelected ? AppTheme.black : AppTheme.grey400,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppTheme.black : AppTheme.grey400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
