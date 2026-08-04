import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tracking_controller.dart';
import 'sort_tracker.dart';
import 'sort_config.dart';
import 'tracked_object.dart';
import 'track_state.dart';

/// Provider dla TrackingController
/// 
/// SortTracker istnieje przez całą sesję przejazdu.
/// Nie jest odtwarzany przy rebuildach UI.
final trackingControllerProvider =
    StateNotifierProvider<TrackingController, TrackingState>((ref) {
  return TrackingController();
});

/// Provider dla konfiguracji trackera
final trackingConfigProvider = Provider<SortConfig>((ref) {
  return SortConfig.defaultConfig;
});

/// Provider dla listy tracków
final trackedObjectsProvider = Provider<List<TrackedObject>>((ref) {
  final state = ref.watch(trackingControllerProvider);
  return state.objects;
});

/// Provider dla potwierdzonych tracków (CONFIRMED)
final confirmedTracksProvider = Provider<List<TrackedObject>>((ref) {
  final state = ref.watch(trackingControllerProvider);
  return state.objects.where((t) => t.state == TrackState.confirmed).toList();
});

/// Provider dla statystyk trackera
final trackingStatsProvider = Provider<TrackingStats>((ref) {
  final state = ref.watch(trackingControllerProvider);
  return TrackingStats(
    totalTracks: state.objects.length,
    confirmedTracks:
        state.objects.where((t) => t.state == TrackState.confirmed).length,
    tentativeTracks:
        state.objects.where((t) => t.state == TrackState.tentative).length,
    lostTracks: state.objects.where((t) => t.state == TrackState.lost).length,
    processedFrames: state.processedFrames,
    lastProcessingTime: state.lastProcessingTime,
  );
});

/// Statystyki trackera
class TrackingStats {
  final int totalTracks;
  final int confirmedTracks;
  final int tentativeTracks;
  final int lostTracks;
  final int processedFrames;
  final Duration lastProcessingTime;

  const TrackingStats({
    required this.totalTracks,
    required this.confirmedTracks,
    required this.tentativeTracks,
    required this.lostTracks,
    required this.processedFrames,
    required this.lastProcessingTime,
  });

  /// Średni FPS przetwarzania
  double get averageFps {
    if (processedFrames == 0) return 0;
    return 1000 / lastProcessingTime.inMilliseconds;
  }
}
