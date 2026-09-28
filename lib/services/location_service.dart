import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../core/errors/failure.dart';
import 'permission_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final PermissionService _permissionService = PermissionService();

  /// Fresh GPS fix laata hai. Koi radius / accuracy validation yahan nahi hai,
  /// wo backend karega. Purani (last known) location kabhi use nahi hoti.
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
        "Couldn't get a GPS fix. Please wait a few seconds near a window or open area and try again.",
        code: "GPS_UNAVAILABLE",
      );
    } catch (_) {
      throw const LocationFailure(
        message: "Couldn't read your location. Please try again.",
        code: "GPS_UNAVAILABLE",
      );
    }
  }

  /// Kuch seconds tak live readings sunta hai aur sabse accurate wali deta hai.
  /// Ye validation nahi hai, sirf best reading chunna hai.
  Future<Position> _bestFreshFix() async {
    Position? best;
    final completer = Completer<Position>();
    late StreamSubscription<Position> sub;

    final timer = Timer(const Duration(seconds: 12), () {
      if (completer.isCompleted) return;
      if (best != null) {
        completer.complete(best!);
      } else {
        completer.completeError(TimeoutException("no gps fix"));
      }
    });

    sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      ),
    ).listen(
          (p) {
        if (best == null || p.accuracy < best!.accuracy) best = p;
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
      timer.cancel();
      await sub.cancel();
    }
  }

  bool isMockLocation(Position position) => position.isMocked;
}