import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../core/errors/failure.dart';
import 'permission_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final PermissionService _permissionService = PermissionService();

  /// Fresh GPS fix. Position.isMocked ko caller check karega.
  Future<Position> getCurrentLocation() async {
    await _permissionService.ensureLocationPermission();

    final gpsEnabled = await _permissionService.isGpsEnabled();
    if (!gpsEnabled) {
      throw const LocationFailure(
        message: "Please turn on location/GPS to mark attendance.",
        code: "GPS_PERMISSION_REQUIRED",
      );
    }

    await _permissionService.ensurePreciseLocation();

    try {
      return await _bestFreshFix();
    } on LocationServiceDisabledException {
      throw const LocationFailure(
        message: "Location services are disabled.",
        code: "GPS_PERMISSION_REQUIRED",
      );
    } on TimeoutException {
      throw const LocationFailure(
        message:
        "Couldn't get a GPS fix. Make sure Location is on and go near a window or open area. "
            "If you recently used a fake GPS app, turn Location off and on again (or restart your phone).",
        code: "GPS_UNAVAILABLE",
      );
    } catch (_) {
      throw const LocationFailure(
        message: "Couldn't read your location. Please try again.",
        code: "GPS_UNAVAILABLE",
      );
    }
  }

  /// Pehle normal (Fused) provider se try, fix na mile to seedha Android
  /// LocationManager (real GPS chip) se. Fake GPS app hatane ke baad kabhi-kabhi
  /// Fused provider atak jaata hai; LocationManager us case me kaam kar jaata hai.
  Future<Position> _bestFreshFix() async {
    try {
      return await _listenForFix(
        forceLocationManager: false,
        hardTimeout: const Duration(seconds: 8),
      );
    } on TimeoutException {
      return _listenForFix(
        forceLocationManager: true,
        hardTimeout: const Duration(seconds: 8),
      );
    }
  }

  Future<Position> _listenForFix({
    required bool forceLocationManager,
    required Duration hardTimeout,
  }) async {
    Position? best;
    final completer = Completer<Position>();
    StreamSubscription<Position>? sub;

    // Soft deadline: 5 sec baad koi bhi reading mil chuki ho to best wali de do.
    // (Indoor accuracy aksar 30-70m hoti hai, 20m ka wait poora timeout kha jaata tha.
    //  Accuracy ka final faisla backend karta hai.)
    final softTimer = Timer(const Duration(seconds: 5), () {
      final b = best;
      if (!completer.isCompleted && b != null) completer.complete(b);
    });

    // Hard deadline
    final hardTimer = Timer(hardTimeout, () {
      if (completer.isCompleted) return;
      final b = best;
      if (b != null) {
        completer.complete(b);
      } else {
        completer.completeError(TimeoutException("no gps fix"));
      }
    });

    sub = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 1),
        forceLocationManager: forceLocationManager,
      ),
    ).listen(
          (p) {
        final b = best;
        if (b == null || p.accuracy < b.accuracy) best = p;
        // Achhi reading mil gayi to jaldi return (rejection nahi, sirf early stop).
        if (p.accuracy <= 20 && !completer.isCompleted) {
          completer.complete(best!);
        }
      },
      onError: (e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
    );

    try {
      return await completer.future;
    } finally {
      softTimer.cancel();
      hardTimer.cancel();
      await sub.cancel();
    }
  }
}