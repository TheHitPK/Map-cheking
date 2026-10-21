import 'dart:async';

import 'package:geolocator/geolocator.dart';

enum LocationIssue { serviceDisabled, denied, deniedForever }

class Fix {
  const Fix({required this.lat, required this.lon, required this.accuracyMeters, required this.mocked, required this.time});

  final double lat;
  final double lon;
  final double accuracyMeters;

  /// Set by Android when the fix comes from a mock-location app.
  final bool mocked;
  final DateTime time;

  factory Fix.fromPosition(Position p) => Fix(
        lat: p.latitude,
        lon: p.longitude,
        accuracyMeters: p.accuracy,
        mocked: p.isMocked,
        time: p.timestamp,
      );
}

/// Foreground location only: the GPS runs while the worker's screen is open, never in background.
class LocationService {
  const LocationService();

  static const _settings = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5);

  /// Null when location is usable; asks for permission once if needed.
  Future<LocationIssue?> ensureReady() async {
    if (!await Geolocator.isLocationServiceEnabled()) return LocationIssue.serviceDisabled;
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    return switch (p) {
      LocationPermission.denied || LocationPermission.unableToDetermine => LocationIssue.denied,
      LocationPermission.deniedForever => LocationIssue.deniedForever,
      _ => null,
    };
  }

  Stream<Fix> watch() => Geolocator.getPositionStream(locationSettings: _settings).map(Fix.fromPosition);

  /// A fresh fix for the mark itself.
  Future<Fix> current() async => Fix.fromPosition(await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 20)),
      ));

  Future<void> openSettings(LocationIssue issue) => issue == LocationIssue.serviceDisabled
      ? Geolocator.openLocationSettings()
      : Geolocator.openAppSettings();
}
