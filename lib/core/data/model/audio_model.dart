class AudioModel {
  final String id;
  final String title;
  final String artist;
  final String imagePath;
  final String duration;
  final String filePath;
  final bool isFavorite;

  AudioModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    required this.filePath,
    this.imagePath = 'assets/images/podcast.png',
    this.isFavorite = false,
  });

  AudioModel copyWith({
    String? id,
    String? title,
    String? artist,
    String? imagePath,
    String? duration,
    String? filePath,
    bool? isFavorite,
  }) {
    return AudioModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      imagePath: imagePath ?? this.imagePath,
      duration: duration ?? this.duration,
      filePath: filePath ?? this.filePath,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
