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

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }

      // Parse error response
      try {
        final errorData = json.decode(response.body);
        final errorMessage =
            errorData['message'] ?? errorData['error'] ?? 'Unknown error';

        // Check for detailed errors array (like face detection failures)
        if (errorData['errors'] != null && errorData['errors'] is List) {
          final errors = errorData['errors'] as List;
          if (errors.isNotEmpty) {
            final firstError = errors[0];
            final specificError = firstError['error'] ?? errorMessage;
            throw Exception(specificError);
          }
        }

        throw Exception(errorMessage);
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to add face (${response.statusCode})');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Connect to SSE stream for real-time attendance updates
  Stream<AttendanceRecord> connectSSE() async* {
    print('🔵 SSE: Connecting to $baseUrl/api/attendance/stream');
    final request =
        http.Request('GET', Uri.parse('$baseUrl/api/attendance/stream'));
    request.headers['Accept'] = 'text/event-stream';
    request.headers['Cache-Control'] = 'no-cache';

    try {
      final streamedResponse = await client.send(request);
      print(
          '🔵 SSE: Connection response status: ${streamedResponse.statusCode}');

      if (streamedResponse.statusCode == 200) {
        print('✅ SSE: Connected successfully, listening for events...');
        StringBuffer buffer = StringBuffer();

        await for (var chunk
            in streamedResponse.stream.transform(utf8.decoder)) {
          print('📦 SSE: Received chunk: ${chunk.replaceAll('\n', '\\n')}');
          buffer.write(chunk);
          var lines = buffer.toString().split('\n\n');
          buffer.clear();

          // Keep last incomplete line in buffer
          if (!chunk.endsWith('\n\n')) {
            buffer.write(lines.removeLast());
          }

          for (var line in lines) {
            if (line.trim().isEmpty) continue;

            print('📝 SSE: Processing line: ${line.replaceAll('\n', '\\n')}');

            // SSE events can have multiple lines (event: ...\ndata: ...)
            // Split by newline and find the data line
            var eventLines = line.split('\n');
            for (var eventLine in eventLines) {
              var dataPrefix = 'data: ';
              if (eventLine.trim().startsWith(dataPrefix)) {
                var jsonStr = eventLine
                    .substring(
                        eventLine.indexOf(dataPrefix) + dataPrefix.length)
                    .trim();
                print('🔍 SSE: Parsing JSON: $jsonStr');
                try {
                  var data = json.decode(jsonStr);
                  print(
                      '✅ SSE: Successfully parsed record: ${data['name']} (${data['status']})');
                  yield AttendanceRecord.fromJson(data);
                } catch (e) {
                  print('❌ SSE: Failed to parse JSON: $e');
                  continue;
                }
              }
            }
          }
        }
        print('⚠️ SSE: Stream ended');
      } else {
        print(
            '❌ SSE: Connection failed with status: ${streamedResponse.statusCode}');
        throw Exception(
            'SSE connection failed: ${streamedResponse.statusCode}');
      }
    } catch (e) {
      print('❌ SSE: Error: $e');
      throw Exception('Error connecting to SSE: $e');
    }
  }

  // Recognize face from image
  Future<Map<String, dynamic>> recognizeFace(String imagePath) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/attendance'),
      );

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imagePath,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      }

      throw Exception('Recognition failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error recognizing face: $e');
    }
  }

  void dispose() {
    client.close();
  }
}
