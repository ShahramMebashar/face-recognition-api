class Face {
  final String name;
  final int imageCount;

  Face({
    required this.name,
    required this.imageCount,
  });

  factory Face.fromJson(Map<String, dynamic> json) {
    return Face(
      name: json['name'] as String,
      imageCount: json['image_count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'image_count': imageCount,
    };
  }
}
