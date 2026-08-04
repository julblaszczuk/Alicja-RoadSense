/// Stany cyklu życia tracku
enum TrackState {
  /// Nowy track, wymaga potwierdzenia
  tentative,

  /// Potwierdzony track z stabilnymi detekcjami
  confirmed,

  /// Track tymczasowo utracony (brak detekcji)
  lost,

  /// Track usunięty (przeterminowany)
  deleted,
}
