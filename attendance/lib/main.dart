import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/attendance_api_service.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with your API URL
    const apiBaseUrl =
        'http://facerecognition-attendance-w1hldw-e52aca-46-62-229-91.traefik.me'; // http://facerecognition-attendance-w1hldw-e52aca-46-62-229-91.traefik.me
    final apiService = AttendanceApiService(baseUrl: apiBaseUrl);

    return MaterialApp(
      title: 'Attendance',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: HomeScreen(apiService: apiService),
    );
  }
}
