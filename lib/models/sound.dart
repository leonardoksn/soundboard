class Sound {
  final int? id;
  final String name;
  final String filePath;
  final int color;
  final int position;
  final bool loop;

  const Sound({
    this.id,
    required this.name,
    required this.filePath,
    required this.color,
    required this.position,
    this.loop = false,
  });

  Sound copyWith({
    int? id,
    String? name,
    String? filePath,
    int? color,
    int? position,
    bool? loop,
  }) {
    return Sound(
      id: id ?? this.id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      color: color ?? this.color,
      position: position ?? this.position,
      loop: loop ?? this.loop,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'file_path': filePath,
      'color': color,
      'position': position,
      'loop': loop ? 1 : 0,
    };
  }

  factory Sound.fromMap(Map<String, Object?> map) {
    return Sound(
      id: map['id'] as int?,
      name: map['name'] as String,
      filePath: map['file_path'] as String,
      color: map['color'] as int,
      position: map['position'] as int,
      loop: (map['loop'] as int? ?? 0) == 1,
    );
  }
}
