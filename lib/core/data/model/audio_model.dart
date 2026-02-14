class AudioModel {
  final String id;
  final String title;
  final String artist;
  final String duration;
  final String filePath;
  final int artworkId; // MediaStore ID used to query album art
  final bool isFavorite;

  AudioModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    required this.filePath,
    this.artworkId = 0,
    this.isFavorite = false,
  });

  AudioModel copyWith({
    String? id,
    String? title,
    String? artist,
    String? duration,
    String? filePath,
    int? artworkId,
    bool? isFavorite,
  }) {
    return AudioModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      duration: duration ?? this.duration,
      filePath: filePath ?? this.filePath,
      artworkId: artworkId ?? this.artworkId,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
