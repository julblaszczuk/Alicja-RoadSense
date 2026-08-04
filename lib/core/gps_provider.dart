import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

class GpsPosition {
  final double latitude;
  final double longitude;
  final double altitude;
  final double speed; // m/s
  final double heading; // degrees
  final double accuracy;
  final DateTime timestamp;

  GpsPosition({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.speed,
    required this.heading,
    required this.accuracy,
    required this.timestamp,
  });

  double get speedKmh => speed * 3.6;

  factory GpsPosition.fromPosition(Position position) {
    return GpsPosition(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      speed: position.speed ?? 0.0,
      heading: position.heading ?? 0.0,
      accuracy: position.accuracy ?? 0.0,
      timestamp: position.timestamp ?? DateTime.now(),
    );
  }

  double distanceTo(GpsPosition other) {
    const double earthRadius = 6371000; // meters
    final double dLat = _degToRad(other.latitude - latitude);
    final double dLon = _degToRad(other.longitude - longitude);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(latitude)) * cos(_degToRad(other.latitude)) *
            sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degToRad(double deg) => deg * (pi / 180.0);
}

class GpsManager {
  Stream<Position>? _positionStream;
  GpsPosition? _lastPosition;
  GpsPosition? _ currentPosition;

  GpsPosition? get currentPosition => _currentPosition;
  GpsPosition? get lastPosition => _lastPosition;

  Future<bool> checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  Stream<GpsPosition> startLocationUpdates() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // minimum 5 meters between updates
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    );

    return _positionStream!.map((position) {
      _lastPosition = _currentPosition;
      _currentPosition = GpsPosition.fromPosition(position);
      return _currentPosition!;
    });
  }

  void stopLocationUpdates() {
    _positionStream = null;
  }

  double? getRelativeSpeed(GpsPosition objectPosition) {
    if (_currentPosition == null) return null;
    // Uproszczone - w rzeczywistości potrzebujemy wektora prędkości obiektu
    return _currentPosition!.speed - objectPosition.speed;
  }
}

final gpsManagerProvider = Provider<GpsManager>((ref) {
  return GpsManager();
});

final gpsPositionProvider = StreamProvider<GpsPosition>((ref) {
  final gpsManager = ref.watch(gpsManagerProvider);
  return gpsManager.startLocationUpdates();
});

final currentSpeedProvider = Provider<double>((ref) {
  final position = ref.watch(gpsPositionProvider).valueOrNull;
  return position?.speedKmh ?? 0.0;
});

final currentHeadingProvider = Provider<double>((ref) {
  final position = ref.watch(gpsPositionProvider).valueOrNull;
  return position?.heading ?? 0.0;
});
