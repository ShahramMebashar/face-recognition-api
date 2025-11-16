class AttendanceStats {
  final int total;
  final int authorized;
  final int unauthorized;
  final int uniquePeople;

  AttendanceStats({
    required this.total,
    required this.authorized,
    required this.unauthorized,
    required this.uniquePeople,
  });

  factory AttendanceStats.fromJson(Map<String, dynamic> json) {
    return AttendanceStats(
      total: json['total'] as int,
      authorized: json['authorized'] as int,
      unauthorized: json['unauthorized'] as int,
      uniquePeople: json['unique_people'] as int,
    );
  }

  double get authorizedPercentage => total > 0 ? (authorized / total) * 100 : 0;

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'authorized': authorized,
      'unauthorized': unauthorized,
      'unique_people': uniquePeople,
    };
  }
}
