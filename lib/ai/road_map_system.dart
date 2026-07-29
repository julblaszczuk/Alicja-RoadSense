import 'dart:math' as math;

/// Typ grupy punktów na mapie
enum MapPointGroupType {
  curb, // krawężnik
  lane, // pas ruchu
  temporary, // obiekty tymczasowe (zwierzęta, stojące samochody)
  roadWork, // roboty drogowe
  accident, // wypadek
  trafficSign, // znak drogowy
  custom, // niestandardowa grupa
}

/// Pojedynczy punkt na mapie
class MapPoint {
  final String id;
  final double latitude;
  final double longitude;
  final double? altitude;
  final DateTime timestamp;
  final MapPointGroupType? groupType;
  final String? groupId;
  final Map<String, dynamic> metadata;

  MapPoint({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.altitude,
    DateTime? timestamp,
    this.groupType,
    this.groupId,
    Map<String, dynamic>? metadata,
  })  : timestamp = timestamp ?? DateTime.now(),
        metadata = metadata ?? {};

  MapPoint copyWith({
    String? id,
    double? latitude,
    double? longitude,
    double? altitude,
    DateTime? timestamp,
    MapPointGroupType? groupType,
    String? groupId,
    Map<String, dynamic>? metadata,
  }) {
    return MapPoint(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      timestamp: timestamp ?? this.timestamp,
      groupType: groupType ?? this.groupType,
      groupId: groupId ?? this.groupId,
      metadata: metadata ?? this.metadata,
    );
  }

  double distanceTo(MapPoint other) {
    const double earthRadius = 6371000; // metry
    final double lat1 = latitude * math.pi / 180;
    final double lat2 = other.latitude * math.pi / 180;
    final double deltaLat =
        (other.latitude - latitude) * math.pi / 180;
    final double deltaLon =
        (other.longitude - longitude) * math.pi / 180;

    final double a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }
}

/// Grupa punktów na mapie
class MapPointGroup {
  final String id;
  final MapPointGroupType type;
  final String name;
  final List<MapPoint> points;
  final DateTime createdAt;
  final DateTime? expiresAt; // dla obiektów tymczasowych
  final bool isTemporary;
  final Map<String, dynamic> metadata;

  MapPointGroup({
    required this.id,
    required this.type,
    required this.name,
    List<MapPoint>? points,
    DateTime? createdAt,
    this.expiresAt,
    bool? isTemporary,
    Map<String, dynamic>? metadata,
  })  : points = points ?? [],
        createdAt = createdAt ?? DateTime.now(),
        isTemporary = isTemporary ?? (type == MapPointGroupType.temporary),
        metadata = metadata ?? {};

  MapPointGroup addPoint(MapPoint point) {
    return MapPointGroup(
      id: id,
      type: type,
      name: name,
      points: [...points, point],
      createdAt: createdAt,
      expiresAt: expiresAt,
      isTemporary: isTemporary,
      metadata: metadata,
    );
  }

  MapPointGroup removePoint(String pointId) {
    return MapPointGroup(
      id: id,
      type: type,
      name: name,
      points: points.where((p) => p.id != pointId).toList(),
      createdAt: createdAt,
      expiresAt: expiresAt,
      isTemporary: isTemporary,
      metadata: metadata,
    );
  }

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  MapPoint? get center {
    if (points.isEmpty) return null;
    final avgLat =
        points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
    final avgLon =
        points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;
    return MapPoint(id: '$id-center', latitude: avgLat, longitude: avgLon);
  }
}

/// Zgłoszenie użytkownika (wypadek, roboty drogowe, itp.)
class UserReport {
  final String id;
  final MapPointGroupType type;
  final String description;
  final MapPoint location;
  final DateTime timestamp;
  final bool isVerified;
  final int confirmationCount;

  UserReport({
    required this.id,
    required this.type,
    required this.description,
    required this.location,
    DateTime? timestamp,
    this.isVerified = false,
    this.confirmationCount = 0,
  }) : timestamp = timestamp ?? DateTime.now();

  UserReport confirm() {
    return UserReport(
      id: id,
      type: type,
      description: description,
      location: location,
      timestamp: timestamp,
      isVerified: confirmationCount + 1 >= 3, // Weryfikacja po 3 potwierdzeniach
      confirmationCount: confirmationCount + 1,
    );
  }
}

/// System mapy punktów
class RoadMapSystem {
  final Map<String, MapPointGroup> _groups = {};
  final List<UserReport> _reports = [];
  final List<MapPoint> _ungroupedPoints = [];

  // Promień grupowania w metrach
  static const double groupingRadius = 5.0;

  /// Dodaj punkt do systemu
  void addPoint(MapPoint point) {
    // Spróbuj dopasować do istniejącej grupy
    final matchedGroup = _findMatchingGroup(point);

    if (matchedGroup != null) {
      _groups[matchedGroup.id] = matchedGroup.addPoint(
        point.copyWith(groupId: matchedGroup.id, groupType: matchedGroup.type),
      );
    } else {
      // Sprawdź czy można utworzyć nową grupę
      final newGroup = _tryCreateGroup(point);
      if (newGroup != null) {
        _groups[newGroup.id] = newGroup;
      } else {
        _ungroupedPoints.add(point);
      }
    }
  }

  /// Znajdź grupę pasującą do punktu
  MapPointGroup? _findMatchingGroup(MapPoint point) {
    for (final group in _groups.values) {
      if (group.isExpired) continue;

      for (final groupPoint in group.points) {
        if (point.distanceTo(groupPoint) <= groupingRadius) {
          return group;
        }
      }
    }
    return null;
  }

  /// Spróbuj utworzyć nową grupę
  MapPointGroup? _tryCreateGroup(MapPoint point) {
    // Sprawdź czy mamy wystarczająco punktów w pobliżu
    final nearbyPoints = _ungroupedPoints
        .where((p) => p.distanceTo(point) <= groupingRadius)
        .toList();

    if (nearbyPoints.length >= 2) {
      // Utwórz nową grupę
      final groupType = _inferGroupType([...nearbyPoints, point]);
      final groupId = 'group-${DateTime.now().millisecondsSinceEpoch}';

      final newGroup = MapPointGroup(
        id: groupId,
        type: groupType,
        name: _generateGroupName(groupType),
        points: nearbyPoints
            .map((p) => p.copyWith(groupId: groupId, groupType: groupType))
            .toList(),
      );

      // Usuń punkty z niegrupowanych
      _ungroupedPoints.removeWhere((p) => nearbyPoints.contains(p));

      return newGroup.addPoint(
        point.copyWith(groupId: groupId, groupType: groupType),
      );
    }

    return null;
  }

  /// Wywnioskuj typ grupy na podstawie punktów
  MapPointGroupType _inferGroupType(List<MapPoint> points) {
    // Prosta heurystyka - w produkcji użyj ML
    if (points.length >= 5) {
      return MapPointGroupType.lane; // Długa linia = pas ruchu
    }
    return MapPointGroupType.curb; // Domyślnie krawężnik
  }

  /// Generuj nazwę grupy
  String _generateGroupName(MapPointGroupType type) {
    switch (type) {
      case MapPointGroupType.curb:
        return 'Krawężnik';
      case MapPointGroupType.lane:
        return 'Pas ruchu';
      case MapPointGroupType.temporary:
        return 'Obiekt tymczasowy';
      case MapPointGroupType.roadWork:
        return 'Roboty drogowe';
      case MapPointGroupType.accident:
        return 'Wypadek';
      case MapPointGroupType.trafficSign:
        return 'Znak drogowy';
      case MapPointGroupType.custom:
        return 'Niestandardowa grupa';
    }
  }

  /// Dodaj zgłoszenie użytkownika
  void addReport(UserReport report) {
    _reports.add(report);

    // Utwórz grupę dla zgłoszenia
    final groupId = 'report-${report.id}';
    final group = MapPointGroup(
      id: groupId,
      type: report.type,
      name: report.description,
      points: [report.location.copyWith(groupId: groupId, groupType: report.type)],
      isTemporary: true,
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    );
    _groups[groupId] = group;
  }

  /// Potwierdź zgłoszenie
  void confirmReport(String reportId) {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      _reports[index] = _reports[index].confirm();
    }
  }

  /// Pobierz wszystkie grupy
  List<MapPointGroup> get groups => _groups.values.toList();

  /// Pobierz grupy według typu
  List<MapPointGroup> getGroupsByType(MapPointGroupType type) {
    return _groups.values.where((g) => g.type == type).toList();
  }

  /// Pobierz wszystkie zgłoszenia
  List<UserReport> get reports => List.unmodifiable(_reports);

  /// Pobierz niegrupowane punkty
  List<MapPoint> get ungroupedPoints => List.unmodifiable(_ungroupedPoints);

  /// Usuń wygasłe grupy
  void cleanupExpired() {
    _groups.removeWhere((_, group) => group.isExpired);
    _reports.removeWhere((r) =>
        r.timestamp.isBefore(DateTime.now().subtract(const Duration(days: 7))));
  }

  /// Wyczyść wszystkie dane
  void clear() {
    _groups.clear();
    _reports.clear();
    _ungroupedPoints.clear();
  }
}
