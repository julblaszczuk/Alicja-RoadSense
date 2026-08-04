import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import '../core/settings_provider.dart';

class AlertManager {
  static final AlertManager _instance = AlertManager._internal();
  factory AlertManager() => _instance;
  AlertManager._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  AppSettings? _settings;

  void setSettings(AppSettings settings) {
    _settings = settings;
  }

  Future<void> playAlert({
    required String soundAsset,
    required bool vibrate,
  }) async {
    if (_settings == null) return;

    // Odtwórz dźwięk jeśli włączony
    if (_settings!.enableSound) {
      try {
        await _audioPlayer.setVolume(_settings!.alertVolume);
        await _audioPlayer.play(AssetSource(soundAsset));
      } catch (e) {
        debugPrint('Audio error: $e');
      }
    }

    // Wibracja jeśli włączona
    if (vibrate && _settings!.enableVibration) {
      try {
        final hasVibrator = await Vibration.hasVibrator() ?? false;
        if (hasVibrator) {
          await Vibration.vibrate(duration: 500);
        }
      } catch (e) {
        debugPrint('Vibration error: $e');
      }
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
