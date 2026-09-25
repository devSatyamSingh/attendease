import 'package:geolocator/geolocator.dart';
import '../core/constants/app_constants.dart';
import '../core/errors/failure.dart';
import 'permission_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final PermissionService _permissionService = PermissionService();

  Future<Position> getCurrentLocation() async {
    await _permissionService.ensureLocationPermission();

    final gpsEnabled = await _permissionService.isGpsEnabled();
    if (!gpsEnabled) {
      throw const LocationFailure(
        message: "Please turn on location/GPS to mark attendance.",
        code: "GPS_PERMISSION_REQUIRED",
      );
    }

    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on LocationServiceDisabledException {
      throw const LocationFailure(
        message: "Location services are disabled.",
        code: "GPS_PERMISSION_REQUIRED",
      );
    } catch (_) {
      // Tunnel / basement / poor signal, or the 15s timeout hit — fall
      // back to the last known fix instead of failing the whole
      // check-in outright.
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown == null) {
        throw const LocationFailure(
          message:
          "Could not get your location. Please try again in an open area.",
          code: "GPS_ACCURACY_LOW",
        );
      }
      position = lastKnown;
    }


    if (position.accuracy > AppConstants.gpsAccuracyThresholdMeters) {
      throw LocationFailure(
        message:
        "GPS accuracy is too low (±${position.accuracy.round()}m). Move to an open area and try again.",
        code: "GPS_ACCURACY_LOW",
      );
    }

    return position;
  }

  bool isMockLocation(Position position) => position.isMocked;
}