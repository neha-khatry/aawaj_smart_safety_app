class Recording {
  final String id;
  final String type; // 'audio' or 'video'
  final String path;
  final String size;
  final int duration;
  final DateTime createdAt;

  Recording({
    required this.id,
    required this.type,
    required this.path,
    required this.size,
    required this.duration,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Recording.fromJson(Map<String, dynamic> json) {
    return Recording(
      id: json['id'],
      type: json['type'],
      path: json['path'],
      size: json['size'],
      duration: json['duration'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'path': path,
      'size': size,
      'duration': duration,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get formattedDuration {
    final hours = (duration ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((duration % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (duration % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
  }
}
