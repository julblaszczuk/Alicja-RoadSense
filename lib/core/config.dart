import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppConfig {
  final double detectionConfidenceThreshold;
  final double ttcCriticalThreshold;
  final double ttcHighThreshold;
  final double ttcMediumThreshold;
  final double followingDistanceThreshold;
  final int frameRate;
  final bool enableAudioDetection;
  final bool enableHapticFeedback;
  final bool enableAudioAlerts;
  final double alertVolume;

  const AppConfig({
    this.detectionConfidenceThreshold = 0.6,
    this.ttcCriticalThreshold = 2.0,
    this.ttcHighThreshold = 4.0,
    this.ttcMediumThreshold = 6.0,
    this.followingDistanceThreshold = 1.5,
    this.frameRate = 30,
    this.enableAudioDetection = false,
    this.enableHapticFeedback = true,
    this.enableAudioAlerts = true,
    this.alertVolume = 0.8,
  });

  AppConfig copyWith({
    double? detectionConfidenceThreshold,
    double? ttcCriticalThreshold,
    double? ttcHighThreshold,
    double? ttcMediumThreshold,
    double? followingDistanceThreshold,
    int? frameRate,
    bool? enableAudioDetection,
    bool? enableHapticFeedback,
    bool? enableAudioAlerts,
    double? alertVolume,
  }) {
    return AppConfig(
      detectionConfidenceThreshold:
          detectionConfidenceThreshold ?? this.detectionConfidenceThreshold,
      ttcCriticalThreshold: ttcCriticalThreshold ?? this.ttcCriticalThreshold,
      ttcHighThreshold: ttcHighThreshold ?? this.ttcHighThreshold,
      ttcMediumThreshold: ttcMediumThreshold ?? this.ttcMediumThreshold,
      followingDistanceThreshold:
          followingDistanceThreshold ?? this.followingDistanceThreshold,
      frameRate: frameRate ?? this.frameRate,
      enableAudioDetection:
          enableAudioDetection ?? this.enableAudioDetection,
      enableHapticFeedback:
          enableHapticFeedback ?? this.enableHapticFeedback,
      enableAudioAlerts: enableAudioAlerts ?? this.enableAudioAlerts,
      alertVolume: alertVolume ?? this.alertVolume,
    );
  }
}

final configProvider = StateProvider<AppConfig>((ref) => const AppConfig());
