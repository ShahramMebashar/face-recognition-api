import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/face.dart';
import '../models/attendance_record.dart';
import '../models/attendance_stats.dart';

class AttendanceApiService {
  final String baseUrl;
  final http.Client client;

  AttendanceApiService({
    required this.baseUrl,
    http.Client? client,
  }) : client = client ?? http.Client();

  // Get list of all registered faces
  Future<List<Face>> getFaces() async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/faces'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> facesJson = data['faces'] ?? [];
          return facesJson.map((json) => Face.fromJson(json)).toList();
        }
      }
      throw Exception('Failed to load faces: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching faces: $e');
    }
  }

  // Get recent attendance records
  Future<List<AttendanceRecord>> getRecentAttendance({int limit = 20}) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/attendance/recent?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> recordsJson = data['records'] ?? [];
          return recordsJson
              .map((json) => AttendanceRecord.fromJson(json))
              .toList();
        }
      }
      throw Exception('Failed to load attendance: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching attendance: $e');
    }
  }

  // Get attendance statistics
  Future<AttendanceStats> getStats() async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/attendance/stats'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return AttendanceStats.fromJson(data['stats']);
        }
      }
      throw Exception('Failed to load stats: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching stats: $e');
    }
  }

  // Add new face with multiple images
  Future<bool> addFace({
    required String name,
    required List<String> imagePaths,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/faces/upload'),
      );

      request.fields['name'] = name;

      for (var imagePath in imagePaths) {
        request.files.add(await http.MultipartFile.fromPath(
          'images',
          imagePath,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      throw Exception('Failed to add face: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error adding face: $e');
    }
  }

  // Connect to SSE stream for real-time attendance updates
  Stream<AttendanceRecord> connectSSE() async* {
    final request =
        http.Request('GET', Uri.parse('$baseUrl/api/attendance/stream'));
    request.headers['Accept'] = 'text/event-stream';
    request.headers['Cache-Control'] = 'no-cache';

    try {
      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode == 200) {
        StringBuffer buffer = StringBuffer();

        await for (var chunk
            in streamedResponse.stream.transform(utf8.decoder)) {
          buffer.write(chunk);
          var lines = buffer.toString().split('\n\n');
          buffer.clear();

          // Keep last incomplete line in buffer
          if (!chunk.endsWith('\n\n')) {
            buffer.write(lines.removeLast());
          }

          for (var line in lines) {
            if (line.trim().isEmpty) continue;

            // Parse SSE format: "data: {...}"
            var dataPrefix = 'data: ';
            if (line.startsWith(dataPrefix)) {
              var jsonStr = line.substring(dataPrefix.length).trim();
              try {
                var data = json.decode(jsonStr);
                yield AttendanceRecord.fromJson(data);
              } catch (e) {
                // Skip malformed JSON
                continue;
              }
            }
          }
        }
      } else {
        throw Exception(
            'SSE connection failed: ${streamedResponse.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to SSE: $e');
    }
  }

  void dispose() {
    client.close();
  }
}
