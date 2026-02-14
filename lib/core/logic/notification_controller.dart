import 'package:audio_service/audio_service.dart';
import 'package:mp3_player_v2/core/logic/audio_handler.dart';

class NotificationController {
  const NotificationController._();

  static Future<AppAudioHandler> initialize() {
    return AudioService.init(
      builder: AppAudioHandler.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.mp3_player_v2.audio',
        androidNotificationChannelName: 'MP3 Player',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
  }
}