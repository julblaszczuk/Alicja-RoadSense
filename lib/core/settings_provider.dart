import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppSettings {
  final double detectionConfidence;
  final double alertVolume;
  final bool enableSound;
  final bool enableVibration;
  final bool detectPedestrians;
  final bool detectVehicles;

  const AppSettings({
    this.detectionConfidence = 0.6,
    this.alertVolume = 0.8,
    this.enableSound = true,
    this.enableVibration = true,
    this.detectPedestrians = true,
    this.detectVehicles = true,
  });

  AppSettings copyWith({
    double? detectionConfidence,
    double? alertVolume,
    bool? enableSound,
    bool? enableVibration,
    bool? detectPedestrians,
    bool? detectVehicles,
  }) {
    return AppSettings(
      detectionConfidence: detectionConfidence ?? this.detectionConfidence,
      alertVolume: alertVolume ?? this.alertVolume,
      enableSound: enableSound ?? this.enableSound,
      enableVibration: enableVibration ?? this.enableVibration,
      detectPedestrians: detectPedestrians ?? this.detectPedestrians,
      detectVehicles: detectVehicles ?? this.detectVehicles,
    );
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(const AppSettings());

  void setDetectionConfidence(double value) {
    state = state.copyWith(detectionConfidence: value);
  }

  void setAlertVolume(double value) {
    state = state.copyWith(alertVolume: value);
  }

  void setEnableSound(bool value) {
    state = state.copyWith(enableSound: value);
  }

  void setEnableVibration(bool value) {
    state = state.copyWith(enableVibration: value);
  }

  void setDetectPedestrians(bool value) {
    state = state.copyWith(detectPedestrians: value);
  }

  void setDetectVehicles(bool value) {
    state = state.copyWith(detectVehicles: value);
  }
}

final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings>(
  (ref) => AppSettingsNotifier(),
);
