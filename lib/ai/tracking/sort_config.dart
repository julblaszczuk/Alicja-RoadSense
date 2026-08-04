/// Konfiguracja SORT tracker
class SortConfig {
  /// Minimalna pewność detekcji do utworzenia tracku
  final double highConfidenceThreshold;

  /// Pewność poniżej której track jest oznaczany jako słaby
  final double lowConfidenceThreshold;

  /// Minimalne IoU dla dopasowania detekcji do tracku
  final double iouThreshold;

  /// Minimalna liczba trafień przed potwierdzeniem tracku
  final int minHits;

  /// Czas po którym niepotwierdzony track jest usuwany
  final Duration tentativeTimeout;

  /// Czas po którym utracony track jest usuwany
  final Duration lostTimeout;

  /// Maksymalna długość historii trajektorii
  final int trajectoryLength;

  /// Maksymalna liczba aktywnych tracków
  final int maxTracks;

  const SortConfig({
    this.highConfidenceThreshold = 0.45,
    this.lowConfidenceThreshold = 0.20,
    this.iouThreshold = 0.30,
    this.minHits = 3,
    this.tentativeTimeout = const Duration(milliseconds: 300),
    this.lostTimeout = const Duration(milliseconds: 800),
    this.trajectoryLength = 20,
    this.maxTracks = 100,
  });

  /// Domyślna konfiguracja
  static const SortConfig defaultConfig = SortConfig();

  /// Konfiguracja dla lepszej dokładności
  static const SortConfig highAccuracyConfig = SortConfig(
    highConfidenceThreshold: 0.55,
    lowConfidenceThreshold: 0.30,
    iouThreshold: 0.40,
    minHits: 4,
    tentativeTimeout: Duration(milliseconds: 500),
    lostTimeout: Duration(milliseconds: 1000),
  );

  /// Konfiguracja dla lepszej wydajności
  static const SortConfig performanceConfig = SortConfig(
    highConfidenceThreshold: 0.40,
    lowConfidenceThreshold: 0.15,
    iouThreshold: 0.25,
    minHits: 2,
    tentativeTimeout: Duration(milliseconds: 200),
    lostTimeout: Duration(milliseconds: 500),
    maxTracks: 50,
  );
}
