import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../ttc_engine.dart';
import '../risk_scorer.dart';
import '../../core/gps_provider.dart';
import 'sort_tracker.dart';
import 'tracked_object.dart';
import 'track_state.dart';

/// Stan trackera z TTC i Risk Assessment
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
  
  /// TTC dla każdego tracku (trackId -> ttc w sekundach)
  final Map<int, double?> ttcMap;
  
  /// Risk assessment dla każdego tracku (trackId -> RiskAssessment)
  final Map<int, RiskAssessment> riskMap;
  
  /// Najwyższy poziom ryzyka spośród wszystkich tracków
  final RiskLevel highestRiskLevel;

  const TrackingState({
    this.objects = const [],
    this.processedFrames = 0,
    this.lastProcessingTime = Duration.zero,
    this.error,
    this.sessionId = 0,
    this.ttcMap = const {},
    this.riskMap = const {},
    this.highestRiskLevel = RiskLevel.low,
  });

  TrackingState copyWith({
    List<TrackedObject>? objects,
    int? processedFrames,
    Duration? lastProcessingTime,
    String? error,
    int? sessionId,
    Map<int, double?>? ttcMap,
    Map<int, RiskAssessment>? riskMap,
    RiskLevel? highestRiskLevel,
  }) {
    return TrackingState(
      objects: objects ?? this.objects,
      processedFrames: processedFrames ?? this.processedFrames,
      lastProcessingTime: lastProcessingTime ?? this.lastProcessingTime,
      error: error,
      sessionId: sessionId ?? this.sessionId,
      ttcMap: ttcMap ?? this.ttcMap,
      riskMap: riskMap ?? this.riskMap,
      highestRiskLevel: highestRiskLevel ?? this.highestRiskLevel,
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
  
  /// Silnik TTC
  final TtcEngine _ttcEngine;
  
  /// Oceniacz ryzyka
  final RiskScorer _riskScorer;

  TrackingController({
    SortTracker? tracker,
    TtcEngine? ttcEngine,
    RiskScorer? riskScorer,
  })  : _tracker = tracker ?? SortTracker(),
        _ttcEngine = ttcEngine ?? TtcEngine(),
        _riskScorer = riskScorer ?? RiskScorer(),
        super(const TrackingState()) {
    _sessionClock.start();
  }

  /// Aktualizuje prędkość własnego pojazdu z GPS
  void updateEgoSpeed(GpsPosition? gpsPosition) {
    _ttcEngine.updateEgoSpeed(gpsPosition);
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

      // Oblicz TTC dla wszystkich tracków
      final ttcMap = _ttcEngine.calculateAllTtcs(trackedObjects);

      // Oblicz ryzyko dla wszystkich tracków
      final riskMap = _riskScorer.assessAllRisks(
        trackedObjects,
        ttcMap: ttcMap,
      );

      // Znajdź najwyższy poziom ryzyka
      RiskLevel highestRisk = RiskLevel.low;
      for (final risk in riskMap.values) {
        if (_riskLevelToInt(risk.level) > _riskLevelToInt(highestRisk)) {
          highestRisk = risk.level;
        }
      }

      final processingTime = DateTime.now().difference(startTime);

      _lastProcessedTimestampUs = currentTimestampUs;

      state = state.copyWith(
        objects: trackedObjects,
        processedFrames: state.processedFrames + 1,
        lastProcessingTime: processingTime,
        error: null,
        ttcMap: ttcMap,
        riskMap: riskMap,
        highestRiskLevel: highestRisk,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
      );
    } finally {
      _isProcessing = false;
    }
  }

  /// Konwertuje RiskLevel na int dla porównania
  int _riskLevelToInt(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return 0;
      case RiskLevel.medium:
        return 1;
      case RiskLevel.high:
        return 2;
      case RiskLevel.critical:
        return 3;
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

  /// Zwraca TTC dla tracku
  double? getTtc(int trackId) {
    return state.ttcMap[trackId];
  }

  /// Zwraca Risk Assessment dla tracku
  RiskAssessment? getRiskAssessment(int trackId) {
    return state.riskMap[trackId];
  }

  /// Zwraca tracki z krytycznym ryzykiem
  List<TrackedObject> get criticalRiskTracks {
    return state.objects.where((t) {
      final risk = state.riskMap[t.id];
      return risk != null && risk.level == RiskLevel.critical;
    }).toList();
  }

  /// Zwraca tracki z wysokim ryzykiem
  List<TrackedObject> get highRiskTracks {
    return state.objects.where((t) {
      final risk = state.riskMap[t.id];
      return risk != null && 
          (risk.level == RiskLevel.critical || risk.level == RiskLevel.high);
    }).toList();
  }

  /// Zwraca track z najwyższym ryzykiem
  TrackedObject? get highestRiskTrack {
    if (state.riskMap.isEmpty) return null;
    
    int? highestRiskId;
    double highestScore = -1;
    
    for (final entry in state.riskMap.entries) {
      if (entry.value.score > highestScore) {
        highestScore = entry.value.score;
        highestRiskId = entry.key;
      }
    }
    
    if (highestRiskId == null) return null;
    
    return state.objects.firstWhere(
      (t) => t.id == highestRiskId,
      orElse: () => state.objects.first,
    );
  }
}
