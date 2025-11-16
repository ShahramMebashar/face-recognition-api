class AttendanceRecord {
  final String id;
  final String name;
  final double confidence;
  final DateTime timestamp;
  final String status;

  AttendanceRecord({
    required this.id,
    required this.name,
    required this.confidence,
    required this.timestamp,
    required this.status,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as String,
      name: json['name'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: json['status'] as String,
    );
  }

  bool get isAuthorized => status == 'authorized';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
    };
  }
}
