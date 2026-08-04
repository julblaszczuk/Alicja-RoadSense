import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import 'sort_tracker.dart';
import 'tracked_object.dart';
import 'track_state.dart';

/// Stan trackera
class TrackingState {
  /// Lista śledzonych obiektów
  final List<TrackedObject> objects;
  
  /// Liczba przetworzonych klatek
  final int processedFrames;
  
  /// Czas ostatniego przetwarzania
  final Duration lastProcessingTime;
  
  /// Błąd jeśli wystąpił
  final String? error;
  
  /// ID sesji (do odrzucania starych wyników)
  final int sessionId;

  const TrackingState({
    this.objects = const [],
    this.processedFrames = 0,
    this.lastProcessingTime = Duration.zero,
    this.error,
    this.sessionId = 0,
  });

  TrackingState copyWith({
    List<TrackedObject>? objects,
    int? processedFrames,
    Duration? lastProcessingTime,
    String? error,
    int? sessionId,
  }) {
    return TrackingState(
      objects: objects ?? this.objects,
      processedFrames: processedFrames ?? this.processedFrames,
      lastProcessingTime: lastProcessingTime ?? this.lastProcessingTime,
      error: error,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

/// Kontroler trackera - zarządza SortTracker w sesji
class TrackingController extends StateNotifier<TrackingState> {
  SortTracker _tracker;
  final Stopwatch _sessionClock = Stopwatch();
  int _sessionId = 0;
  bool _isProcessing = false;
  int _lastProcessedTimestampUs = 0;

  TrackingController({SortTracker? tracker})
      : _tracker = tracker ?? SortTracker(),
        super(const TrackingState()) {
    _sessionClock.start();
  }

  /// Przetwarza detekcje z YOLO
  /// 
  /// [detections] - lista detekcji z modelu
  /// [sourceImageSize] - rozmiar obrazu źródłowego (przed przeskalowaniem)
  void processDetections({
    required List<Detection> detections,
    required Size sourceImageSize,
  }) {
    // Backpressure - jeśli przetwarzamy poprzednią klatkę, pomijamy
    if (_isProcessing) {
      return;
    }

    // Sprawdź czy to nie jest stara klatka
    final currentTimestampUs = _sessionClock.elapsedMicroseconds;
    if (currentTimestampUs <= _lastProcessedTimestampUs) {
      return;
    }

    _isProcessing = true;
    final startTime = DateTime.now();

    try {
      // Aktualizuj tracker
      final trackedObjects = _tracker.update(
        detections,
        timestampUs: currentTimestampUs,
      );

      final processingTime = DateTime.now().difference(startTime);

      _lastProcessedTimestampUs = currentTimestampUs;

      state = state.copyWith(
        objects: trackedObjects,
        processedFrames: state.processedFrames + 1,
        lastProcessingTime: processingTime,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
      );
    } finally {
      _isProcessing = false;
    }
  }

  /// Resetuje tracker (nowa sesja)
  void reset() {
    _sessionId++;
    _tracker.reset();
    _sessionClock.reset();
    _sessionClock.start();
    _lastProcessedTimestampUs = 0;
    _isProcessing = false;

    state = TrackingState(
      sessionId: _sessionId,
    );
  }

  /// Zwalnia zasoby
  @override
  void dispose() {
    _sessionClock.stop();
    _tracker.reset();
    super.dispose();
  }

  /// Zwraca tracki w stanie CONFIRMED
  List<TrackedObject> get confirmedTracks {
    return state.objects
        .where((t) => t.state == TrackState.confirmed)
        .toList();
  }

  /// Zwraca wszystkie tracki (w tym TENTATIVE i LOST)
  List<TrackedObject> get allTracks {
    return state.objects;
  }

  /// Czy tracker jest aktywny
  bool get isActive => _sessionClock.isRunning;

  /// Aktualna liczba tracków
  int get trackCount => state.objects.length;

  /// Średni czas przetwarzania
  Duration get averageProcessingTime {
    if (state.processedFrames == 0) return Duration.zero;
    return state.lastProcessingTime;
  }
}
